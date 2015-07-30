import std.algorithm;

import common_types;

interface Recipients {
  void subscribe(MessageSink messageSink);
  void unsubscribe(MessageSink messageSink);
  void broadcast(string message);
}

Recipients createRecipients() {
  return new ListOfRecipients;
}

private class ListOfRecipients : Recipients {
  void subscribe(MessageSink recipient) {
    recipients_ ~= recipient;
  }

  void unsubscribe(MessageSink recipient) {
    recipients_ = remove!(r => r == recipient)(recipients_);
  }

  void broadcast(string message) {
    recipients_.each!(send => send(message));
  }

  private MessageSink[] recipients_;
}

unittest {
  import dunit.toolkit;

  string PREFIX1 = "1: ";
  string PREFIX2 = "2: ";
  const string MSG = "Test message";
  string[] messages;

  auto makeSink = delegate(string prefix) {
    return delegate(string message) {
      messages ~= prefix ~ message;
    };
  };
  auto sink1 = makeSink(PREFIX1);
  auto sink2 = makeSink(PREFIX2);

  auto recipients = createRecipients();
  recipients.subscribe(sink1);
  recipients.subscribe(sink2);

  recipients.broadcast(MSG);
  assertEqual(messages, [PREFIX1 ~ MSG, PREFIX2 ~ MSG]);

  recipients.unsubscribe(sink2);
  recipients.broadcast(MSG);
  assertEqual(messages, [PREFIX1 ~ MSG, PREFIX2 ~ MSG, PREFIX1 ~ MSG]);
}