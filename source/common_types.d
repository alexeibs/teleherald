alias ChatId = int;

alias MessageSink = void delegate(string message);
alias UpdateMessageSink = void delegate(ChatId chat, string message);
