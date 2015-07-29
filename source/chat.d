alias MessageReader = void delegate(string message);

interface Chat {
  string token() const; // internal unique identifier
  bool isActive() const; // chat is inactive if it doesn't have Telegram Chat ID
  int id() const;
  void sendMessage(string message);
  void subscribe(MessageReader messageReader);
  // TODO remove later
  void activate(int chatId);
}

final class RealChat : Chat {
  this(string token) {
    token_ = token;
  }

  string token() const {
    return token_;
  }

  bool isActive() const {
    return isActive_;
  }

  // TODO remove later
  void activate(int chatId) {
    if (!isActive_) {
      chatId_ = chatId;
      isActive_ = true;
    }
  }

  int id() const {
    return chatId_;
  }

  // network interface is required for these methods
  void sendMessage(string message) {}
  void subscribe(MessageReader messageReader) {}

  private string token_;
  private int chatId_;
  private bool isActive_;
}

Chat createChat(string token) {
  return new RealChat(token);
}

unittest {
  import dunit.toolkit;

  string TEST_TOKEN = "token";
  Chat chat = createChat(TEST_TOKEN);

  assertEqual(TEST_TOKEN, chat.token());
  assertFalse(chat.isActive());
  assertEqual(0, chat.id());

  const int CHAT_ID = 37;
  chat.activate(CHAT_ID);
  assertTrue(chat.isActive());
  assertEqual(CHAT_ID, chat.id());

  chat.activate(CHAT_ID + 100); // does nothing second time
  assertEqual(CHAT_ID, chat.id());
}
