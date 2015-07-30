import chat;
import common_types;
import server;

interface ChatCollection {
  void add(Chat chat);
  void remove(Chat chat);
  Chat findByToken(string token);
  Chat findById(ChatId id);
}

ChatCollection createChatCollection() {
  return new ChatCollectionImpl;
}

private class ChatCollectionImpl : ChatCollection {
  void add(Chat chat) {
    string token = chat.token();
    int id = chat.id();
    if (token !in chatsByTokens && id !in chatsByIds) {
      chatsByTokens[token] = chat;
      chatsByIds[id] = chat;
    }
  }

  void remove(Chat chat) {
    string token = chat.token();
    int id = chat.id();
    auto byToken = token in chatsByTokens;
    auto byId = id in chatsByIds;
    if (byToken && byId && *byToken == *byId) {
      chatsByTokens.remove(token);
      chatsByIds.remove(id);
    }
  }

  Chat findByToken(string token) {
    Chat* chat = token in chatsByTokens;
    return chat is null ? null : *chat;
  }

  Chat findById(ChatId id) {
    Chat* chat = id in chatsByIds;
    return chat is null ? null : *chat;
  }

  private Chat[string] chatsByTokens;
  private Chat[int] chatsByIds;
}

unittest {
  import dunit.toolkit;

  class DummyServer : Server {
    void subscribeToEverything(UpdateMessageSink sink) {}
    void subscribe(ChatId chat, MessageSink sink) {
      subscribeToEverything(null);
      sendMessage(0, null);
    }
    void sendMessage(ChatId chat, string message) {}
  }
  auto dummyServer = new DummyServer;

  Chat chat1 = createChat("T1", 1, dummyServer);
  Chat chat2 = createChat("T2", 2, dummyServer);
  Chat invalidChat = createChat("T1", 2, dummyServer);

  auto chats = createChatCollection();

  void checkChats(Chat[] inside, Chat[] outside) {
    foreach (Chat chat; inside) {
      assertEqual(chats.findById(chat.id()), chat);
      assertEqual(chats.findByToken(chat.token()), chat);
    }
    foreach (Chat chat; outside) {
      assertNull(chats.findById(chat.id()));
      assertNull(chats.findByToken(chat.token()));
    }
  }

  checkChats([], [chat1, chat2]);

  chats.add(chat1);
  checkChats([chat1], [chat2]);

  chats.add(chat2);
  checkChats([chat1, chat2], []);

  chats.add(invalidChat);
  checkChats([chat1, chat2], []);

  chats.remove(invalidChat);
  checkChats([chat1, chat2], []);

  chats.remove(chat1);
  checkChats([chat2], [chat1]);

  chats.remove(chat2);
  checkChats([], [chat1, chat2]);
}