import common_types;
import recipients;

interface Server {
  void subscribeToEverything(UpdateMessageSink sink);
  void subscribe(ChatId chat, MessageSink sink);
  void sendMessage(ChatId chat, string message);
}
