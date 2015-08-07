import std.conv;
import std.file;
import std.stdio;
import std.string;

import vibe.core.args;
import vibe.core.concurrency;
import vibe.core.core;
import vibe.core.log;
import vibe.http.router;
import vibe.http.server;
import vibe.web.rest;

import activation_list;
import app;
import chat_collection;
import common_types;
import config;

__gshared Task g_keeperTask;

void runKeeperTask()
{
  auto activationList = createActivationList(null);
  g_keeperTask = runTask({
    while (true) {
      receive(
        (Task target) {
          target.send(activationList.getActivationList());
        },
        (Task target, string chatName) {
          target.send(activationList.postActivationList(chatName));
        });
    }
  });
  runEventLoop();
}

class ActivationRestInterfaceImpl : ActivationRestInterface {
  ActivationEntries getActivationList() {
    g_keeperTask.send(Task.getThis());
    return receiveOnly!ActivationEntries;
  }
  ActivationEntry postActivationList(string chatName) {
    g_keeperTask.send(Task.getThis(), chatName);
    return receiveOnly!ActivationEntry;
  }
}

void showCode(HTTPServerRequest request, HTTPServerResponse response) {
  response.render!("activation.dt", request);
}

shared static this() {
  new core.thread.Thread(&runKeeperTask).start();

  string json;
  try {
    json = readText("teleherald.json");
  } catch(Exception e) {
    writeln("Cannot read config file. Error: ", e.msg);
  }
  auto config = parseConfig(json);

  auto router = new URLRouter;
  router.get("/" ~ config.activatorPath(), &showCode);
  router.registerRestInterface(new ActivationRestInterfaceImpl,
      "/" ~ config.activatorPath() ~ "/", MethodStyle.camelCase);

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  listenHTTP(settings, router);
}

class RealApp : App {
  void start() {
    if (!finalizeCommandLineOptions())
      return;
    lowerPrivileges();
    runEventLoop();
  }
}

void main()
{
  startApp(new RealApp);
}
