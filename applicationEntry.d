import std.conv;
import std.file;
import std.stdio;
import std.string;
import std.regex;

import core.time : msecs;

import vibe.core.args;
import vibe.core.concurrency;
import vibe.core.core;
import vibe.core.log;
import vibe.http.client;
import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;
import vibe.stream.operations : readAllUTF8;
import vibe.web.rest;

import activation_list;
import app;
import chat_collection;
import common_types;
import config;
import telegram_api;

__gshared Task g_commandProcessor;
__gshared Task g_telegramUpdater;
__gshared Config g_config;

enum ActivationTag {_};
enum ChatTag {_};
enum TestTag {_};

immutable string TELEGRAM_BOT_URL = "https://api.telegram.org/bot";

void runCommandProcessor() {
  static class FakeChatServer : ChatServer {
    void sendMessage(ChatId chat, string message) {
      logInfo("ChatServer.sendMessage: ", message, chat);
    }
  }

  auto chatCollection = createChatCollection(new FakeChatServer);
  auto activationList = createActivationList(chatCollection);
  g_commandProcessor = runTask({
    while (true) {
      receive(
        (ActivationTag _, Task target) {
          target.send(activationList.getActivationList());
        },
        (ActivationTag _, Task target, string chatName) {
          target.send(activationList.postActivationList(chatName));
        },
        (ActivationTag _, string chatName, uint code, int chatId) {
          activationList.activateChat(chatName, code, chatId);
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

void runTelegramUpdater() {
  g_telegramUpdater = runTask({
    string updateUrl = TELEGRAM_BOT_URL ~ g_config.appToken ~ "/getUpdates?offset=";
    int maxId = -1;

    auto activationFilter = ctRegex!(q"{^\/start\s+(\d{6,6})\s*$}");

    while (true) {
      requestHTTP(updateUrl ~ to!string(maxId + 1),
        (scope request) {},
        (scope response) {
          try {
            foreach (update; getTelegramUpdates(new JsonResponseImpl(response))) {
              int id = update.id();
              if (maxId < id) {
                maxId = id;
              }
              auto message = update.message();
              auto from = message.from();
              auto chat = message.chat();
              auto text = message.text();
              logInfo("Chat \"%s\": \"%s\" wrote \"%s\"", chat.chatName(), from.chatName(), text);
              auto activationMatch = text.match(activationFilter);
              if (!activationMatch.empty) {
                uint code = activationMatch.captures[1].to!uint;
                logInfo("Activation code received: %d", code);
                g_commandProcessor.send(ActivationTag._, chat.chatName(), code, chat.chatId());
              }
            }
          } catch (Exception error) {
            logError("Error: %s", error.msg);
          }
        }
      );
      sleep(1000.msecs);
    }
  });
  runEventLoop();
}

class JsonResponseImpl : JsonResponse {
  this(HTTPClientResponse response) {
    response_ = response;
  }

  int statusCode() const {
    return response_.statusCode;
  }

  string rawResponse() {
    return response_.bodyReader.readAllUTF8();
  }

  Json json() {
    return response_.readJson();
  }

  private HTTPClientResponse response_;
}

class ActivationRestInterfaceImpl : ActivationRestInterface {
  ActivationEntries getActivationList() {
    g_commandProcessor.send(ActivationTag._, Task.getThis());
    return receiveOnly!ActivationEntries;
  }
  ActivationEntry postActivationList(string chatName) {
    g_commandProcessor.send(ActivationTag._, Task.getThis(), chatName);
    return receiveOnly!ActivationEntry;
  }
}

class ChatRestInterfaceImpl : ChatRestInterface {
  ChatList getChatList() {
    g_commandProcessor.send(ChatTag._, Task.getThis());
    return receiveOnly!ChatList;
  }
}

interface TestInterface {
  bool postActivationCode(string chatName, uint code, int chatId);
}

class TestInterfaceImpl : TestInterface {
  bool postActivationCode(string chatName, uint code, int chatId) {
    g_commandProcessor.send(TestTag._, Task.getThis(), chatName, code, chatId);
    return receiveOnly!bool;
  }
}

void showActivationView(HTTPServerRequest request, HTTPServerResponse response) {
  response.render!("activation.dt", request);
}

shared static this() {
  string json;
  try {
    json = readText("teleherald.json");
  } catch(Exception e) {
    logError("Cannot read config file. Error: %s", e.msg);
  }
  g_config = parseConfig(json);

  new core.thread.Thread(&runCommandProcessor).start();
  new core.thread.Thread(&runTelegramUpdater).start();

  string basePath = "/" ~ g_config.activatorPath();
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
