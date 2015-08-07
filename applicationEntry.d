import std.conv;
import std.file;
import std.stdio;
import std.string;

import vibe.core.args;
import vibe.core.concurrency;
import vibe.core.core;
import vibe.core.log;
import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;
import vibe.web.rest;

import activation_list;
import app;
import chat_collection;
import common_types;
import config;

__gshared Task g_keeperTask;

enum ActivationTag {_};
enum ChatTag {_};
enum TestTag {_};

void runKeeperTask()
{
  static class FakeChatServer : ChatServer {
    void sendMessage(ChatId chat, string message) {
      logInfo("ChatServer.sendMessage: ", message, chat);
    }
  }

  auto chatCollection = createChatCollection(new FakeChatServer);
  auto activationList = createActivationList(chatCollection);
  g_keeperTask = runTask({
    while (true) {
      receive(
        (ActivationTag _, Task target) {
          target.send(activationList.getActivationList());
        },
        (ActivationTag _, Task target, string chatName) {
          target.send(activationList.postActivationList(chatName));
        },
        (ChatTag _, Task target) {
          target.send(chatCollection.getChatList());
        },
        (TestTag _, Task target, string chatName, uint code, int chatId) {
          target.send(activationList.activateChat(chatName, code, chatId));
        });
    }
  });
  runEventLoop();
}

class ActivationRestInterfaceImpl : ActivationRestInterface {
  ActivationEntries getActivationList() {
    g_keeperTask.send(ActivationTag._, Task.getThis());
    return receiveOnly!ActivationEntries;
  }
  ActivationEntry postActivationList(string chatName) {
    g_keeperTask.send(ActivationTag._, Task.getThis(), chatName);
    return receiveOnly!ActivationEntry;
  }
}

class ChatRestInterfaceImpl : ChatRestInterface {
  ChatList getChatList() {
    g_keeperTask.send(ChatTag._, Task.getThis());
    return receiveOnly!ChatList;
  }
}

interface TestInterface {
  bool postActivationCode(string chatName, uint code, int chatId);
}

class TestInterfaceImpl : TestInterface {
  bool postActivationCode(string chatName, uint code, int chatId) {
    g_keeperTask.send(TestTag._, Task.getThis(), chatName, code, chatId);
    return receiveOnly!bool;
  }
}

void showActivationView(HTTPServerRequest request, HTTPServerResponse response) {
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

  string basePath = "/" ~ config.activatorPath();
  string restBasePath = basePath ~ "/";
  auto router = new URLRouter;
  router.get(basePath, &showActivationView);
  router.registerRestInterface(new ActivationRestInterfaceImpl, restBasePath, MethodStyle.camelCase);
  router.registerRestInterface(new ChatRestInterfaceImpl, restBasePath, MethodStyle.camelCase);
  router.registerRestInterface(new TestInterfaceImpl, restBasePath, MethodStyle.camelCase);
  router.get("*", serveStaticFiles("./public/"));

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
