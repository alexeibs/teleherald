import recipients;

alias ChatId = int;

alias MessageSink = void delegate(string message);
alias UpdateMessageSink = void delegate(ChatId chat, string message);

interface Server {
  void subscribeToEverything(UpdateMessageSink sink);
  void subscribe(ChatId chat, MessageSink sink);
  void sendMessage(ChatId chat, string message);
}
