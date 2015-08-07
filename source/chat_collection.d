import common_types;

struct Chat {
  string token;
  string chatName;
  ChatId id;
}

alias ChatList = immutable(Chat)[];

interface ChatRestInterface {
  ChatList getChatList();
}

interface ChatCollection : ChatCreator, ChatRestInterface {
  void sendMessage(string token, string message);
  void removeChat(ChatId id);
}

ChatCollection createChatCollection(ChatServer chatServer) {
  return new ChatCollectionImpl(chatServer);
}

private class ChatCollectionImpl : ChatCollection {
  this(ChatServer chatServer) {
    chatServer_ = chatServer;
  }

  ChatList getChatList() {
    return cast(immutable)chatsByIds_.values.dup;
  }

  void createNewChat(string token, ChatId id, string chatName) {
    if (token !in chatsByTokens_ && id !in chatsByIds_) {
      Chat chat = {token: token, id: id, chatName: chatName};
      chatsByTokens_[token] = chat;
      chatsByIds_[id] = chat;
    }
  }

  void sendMessage(string token, string message) {
    auto chat = token in chatsByTokens_;
    if (chat) {
      chatServer_.sendMessage(chat.id, message);
    }
  }

  void removeChat(ChatId id) {
    auto chat = id in chatsByIds_;
    if (chat) {
      chatsByTokens_.remove(chat.token);
      chatsByIds_.remove(id);
    }
  }

  private Chat[string] chatsByTokens_;
  private Chat[int] chatsByIds_;
  private ChatServer chatServer_;
}

unittest {
  import dunit.toolkit;

  static class FakeServer : ChatServer {
    static string lastMessage;
    static int lastChat;

    void sendMessage(ChatId chat, string message) {
      lastChat = chat;
      lastMessage = message;
    }
  }

  auto chats = createChatCollection(new FakeServer);

  void assertChatExists(ChatId chatId, string token, string message) {
    FakeServer.lastMessage = null;
    FakeServer.lastChat = 0;
    chats.sendMessage(token, message);
    assertEqual(FakeServer.lastChat, chatId);
    assertEqual(FakeServer.lastMessage, message);
  }

  void assertNoChat(string token, string message) {
    FakeServer.lastMessage = null;
    FakeServer.lastChat = 0;
    chats.sendMessage(token, message);
    assertEqual(FakeServer.lastChat, 0);
    assertNull(FakeServer.lastMessage);
  }

  assertNoChat("t1", "ping");
  chats.createNewChat("t1", 1, "chat1");
  assertChatExists(1, "t1", "ping1");
  assertEqual(chats.getChatList(), [Chat("t1", "chat1", 1)]);

  chats.createNewChat("t2", 2, "chat2");
  assertChatExists(2, "t2", "ping2");
  assertEqual(chats.getChatList(), [Chat("t1", "chat1", 1), Chat("t2", "chat2", 2)]);

  chats.createNewChat("t3", 1, "chat3"); // id already exists
  assertNoChat("t3", "ping3");
  assertEqual(chats.getChatList(), [Chat("t1", "chat1", 1), Chat("t2", "chat2", 2)]);

  chats.createNewChat("t2", 3, "chat3"); // token already exists
  assertChatExists(2, "t2", "ping4");
  assertEqual(chats.getChatList(), [Chat("t1", "chat1", 1), Chat("t2", "chat2", 2)]);

  chats.removeChat(5);
  assertChatExists(2, "t2", "ping5");
  assertChatExists(1, "t1", "ping6");
  assertEqual(chats.getChatList(), [Chat("t1", "chat1", 1), Chat("t2", "chat2", 2)]);

  chats.removeChat(1);
  assertNoChat("t1", "ping7");
  assertChatExists(2, "t2", "ping8");
  assertEqual(chats.getChatList(), [Chat("t2", "chat2", 2)]);

  chats.removeChat(2);
  assertNoChat("t1", "ping9");
  assertNoChat("t2", "ping10");
  assertEqual(chats.getChatList(), []);
}