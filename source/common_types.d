alias ChatId = int;

alias MessageSink = void delegate(string message);
alias UpdateMessageSink = void delegate(ChatId chat, string message);

interface ChatServer {
  void sendMessage(ChatId chat, string message);
}

interface ChatCreator {
  void createNewChat(string token, ChatId id);
}
