import server;
import recipients;

interface Chat {
  string token() const; // internal unique identifier
  ChatId id() const;
  void sendMessage(string message);
  void subscribe(MessageSink messageSink);
}

Chat createChat(string token, ChatId id, Server server) {
  return new ChatImpl(token, id, server);
}

private class ChatImpl : Chat {
  this(string token, ChatId id, Server server) {
    token_ = token;
    chatId_ = id;
    recipients_ = createRecipients();
    server_ = server;
    server_.subscribe(id, &this.processMessage);
  }

  string token() const {
    return token_;
  }

  ChatId id() const {
    return chatId_;
  }

  void sendMessage(string message) {
    server_.sendMessage(chatId_, message);
  }

  void subscribe(MessageSink recipient) {
    recipients_.subscribe(recipient);
  }

  private void processMessage(string message) {
    recipients_.broadcast(message);
  }

  private string token_;
  private ChatId chatId_;
  private Server server_;
  private Recipients recipients_;
}

unittest {
  import dunit.toolkit;

  static class TestServer : Server {
    static ChatId lastSender = 0;
    static string lastSentMessage;
    static ChatId lastSubscribedChat = 0;
    static MessageSink lastMessageSink = null;

    void subscribeToEverything(UpdateMessageSink sink) {}
    void subscribe(ChatId chat, MessageSink sink) {
      lastSubscribedChat = chat;
      lastMessageSink = sink;
      subscribeToEverything(null);
    }
    void sendMessage(ChatId chat, string message) {
      lastSender = chat;
      lastSentMessage = message;
    }

    static void sendMessageToSubcriber(string message) {
      lastMessageSink(message);
    }
  }

  Chat chat = createChat("token", 38, new TestServer);

  assertEqual(chat.token(), "token");
  assertEqual(chat.id(), 38);
  assertEqual(TestServer.lastSubscribedChat, chat.id());

  chat.sendMessage("send message to server");
  assertEqual(TestServer.lastSentMessage, "send message to server");

  string messageFromChat;
  chat.subscribe(delegate(string message) {
    messageFromChat = message;
  });
  TestServer.sendMessageToSubcriber("message from server");
  assertEqual(messageFromChat, "message from server");
}
