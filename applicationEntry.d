import std.conv;
import std.file;
import std.stdio;
import std.string;

import vibe.d;
import vibe.vibe;

import activation_list;
import app;
import chat_collection;
import common_types;
import config;

void showCode(HTTPServerRequest request, HTTPServerResponse response) {
  response.render!("activation.dt", request);
}

shared static this() {
  string json;
  try {
    json = readText("teleherald.json");
  } catch(Exception e) {
    writeln("Cannot read config file. Error: ", e.msg);
  }
  auto config = parseConfig(json);

  auto router = new URLRouter;
  router.get("/" ~ config.activatorPath(), &showCode);

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
