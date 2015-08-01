import common_types;

interface Chat {
  string token() const; // internal unique identifier
  ChatId id() const;
}

Chat createChat(string token, ChatId id) {
  return new ChatImpl(token, id);
}

private class ChatImpl : Chat {
  this(string token, ChatId id) {
    token_ = token;
    chatId_ = id;
  }

  string token() const {
    return token_;
  }

  ChatId id() const {
    return chatId_;
  }

  private string token_;
  private ChatId chatId_;
}

unittest {
  import dunit.toolkit;

  Chat chat = createChat("token", 38);

  assertEqual(chat.token(), "token");
  assertEqual(chat.id(), 38);
}
