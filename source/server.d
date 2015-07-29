alias MessageSink = void delegate(string message);
alias UpdateMessageSink = void delegate(ChatContext chat, string message);

struct ChatContext {
  bool isUser;
  int id;
  string name;
}

interface Server {
  void subscribe(UpdateMessageSink sink);
  void subscribe(ChatContext chat, MessageSink sink);
  void sendMessage(ChatContext chat, string message);
}
