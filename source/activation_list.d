import std.random;

import common_types;
import token_generator;

struct ActivationEntry {
  string token;
  string chatName;
  uint code;
}

alias ActivationEntries = immutable(ActivationEntry)[];

interface ActivationRestInterface {
  ActivationEntries getActivationList();
  ActivationEntry postActivationList(string chatName);
}

interface ActivationList : ActivationRestInterface {
  void activateChat(string chatName, int activationCode, int chatId);
}

ActivationList createActivationList(ChatCreator chatCreator) {
  return new ActivationListImpl(chatCreator);
}

private class ActivationListImpl : ActivationList {
  this(ChatCreator chatCreator) {
    chatCreator_ = chatCreator;
    tokenGenerator_ = createTokenGenerator(new MersenneRandomGenerator);
  }

  ActivationEntries getActivationList() {
    return cast(immutable)tokensByChatNames_.values.dup;
  }

  ActivationEntry postActivationList(string chatName) {
    ActivationEntry entry;
    if (chatName !in tokensByChatNames_) {
      entry.token = tokenGenerator_.getToken();
      entry.code = tokenGenerator_.getActivationCode();
      entry.chatName = chatName;
      tokensByChatNames_[chatName] = entry;
    }
    return entry;
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

  private ActivationEntry[string] tokensByChatNames_;
  private TokenGenerator tokenGenerator_;
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

  static class FakeCreator : ChatCreator {
    static int callCount;
    static ChatId lastId;

    void createNewChat(string token, ChatId id) {
      ++callCount;
      lastId = id;
    }
  }

  auto activationList = createActivationList(new FakeCreator);
  assertEqual(activationList.getActivationList().length, 0);

  activationList.postActivationList("chat1");
  auto list = activationList.getActivationList();
  assertEqual(list.length, 1);
  assertEqual(list[0].chatName, "chat1");
  uint code = list[0].code;

  activationList.postActivationList("chat1"); // does nothing second time
  assertEqual(activationList.getActivationList().length, 1);

  activationList.activateChat("chat2", code, 35); // unknown chat
  assertEqual(FakeCreator.callCount, 0);
  assertEqual(activationList.getActivationList().length, 1);

  activationList.activateChat("chat1", code + 1, 35); // incorrect code
  assertEqual(FakeCreator.callCount, 0);
  assertEqual(activationList.getActivationList().length, 1);

  activationList.activateChat("chat1", code, 35);
  assertEqual(FakeCreator.callCount, 1);
  assertEqual(FakeCreator.lastId, 35);
  assertEqual(activationList.getActivationList().length, 0);

  activationList.postActivationList("chat1"); // now we can get a new code
  assertEqual(activationList.getActivationList().length, 1);
}