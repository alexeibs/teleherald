import std.random;

import common_types;
import chat_collection;
import token_generator;

interface ActivationList {
  void makeActivationCode(string chatName);
  void activateChat(string chatName, int activationCode, int chatId);
}

ActivationList createActivationList(ActivationView view, ChatCreator chatCreator) {
  return new ActivationListImpl(view, chatCreator);
}

private struct TokenWithCode {
  string token;
  uint code;
}

private class ActivationListImpl : ActivationList {
  this(ActivationView view, ChatCreator chatCreator) {
    view_ = view;
    chatCreator_ = chatCreator;
    tokenGenerator_ = createTokenGenerator(new MersenneRandomGenerator);
  }

  void makeActivationCode(string chatName) {
    if (chatName !in tokensByChatNames_) {
      TokenWithCode tokenWithCode;
      tokenWithCode.token = tokenGenerator_.getToken();
      tokenWithCode.code = tokenGenerator_.getActivationCode();
      tokensByChatNames_[chatName] = tokenWithCode;

      view_.show(tokenWithCode.code);
    }
  }

  void activateChat(string chatName, int activationCode, int chatId) {
    auto chat = chatName in tokensByChatNames_;
    if (chat && chat.code == activationCode) {
      string token = chat.token;
      tokensByChatNames_.remove(chatName);
      tokenGenerator_.forgetActivationCode(activationCode);

      chatCreator_.createNewChat(chat.token, chatId);
    }
  }

  private TokenWithCode[string] tokensByChatNames_;
  private TokenGenerator tokenGenerator_;
  private ActivationView view_;
  private ChatCreator chatCreator_;
}

private class MersenneRandomGenerator : RandomNumberGenerator {
  this() {
    generator_.seed(unpredictableSeed);
  }

  uint getNumber() {
    generator_.popFront();
    return generator_.front;
  }

  private Mt19937 generator_;
}

unittest {
  import dunit.toolkit;

  static class FakeView : ActivationView {
    static int callCount;
    static int lastCode;
    void show(uint code) {
      ++callCount;
      lastCode = code;
    }
  }

  static class FakeCreator : ChatCreator {
    static int callCount;
    static ChatId lastId;
    void createNewChat(string token, ChatId id) {
      ++callCount;
      lastId = id;
    }
  }

  auto activationList = createActivationList(new FakeView, new FakeCreator);

  activationList.makeActivationCode("chat1");
  assertEqual(FakeView.callCount, 1);

  activationList.makeActivationCode("chat1"); // does nothing second time
  assertEqual(FakeView.callCount, 1);


  activationList.activateChat("chat2", FakeView.lastCode, 35); // unknown chat
  assertEqual(FakeCreator.callCount, 0);

  activationList.activateChat("chat1", FakeView.lastCode + 1, 35); // incorrect code
  assertEqual(FakeCreator.callCount, 0);

  activationList.activateChat("chat1", FakeView.lastCode, 35);
  assertEqual(FakeCreator.callCount, 1);
  assertEqual(FakeCreator.lastId, 35);

  activationList.makeActivationCode("chat1"); // now we can get a new code
  assertEqual(FakeView.callCount, 2);
}