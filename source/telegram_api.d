import std.format : format;

import vibe.data.json : Json;
import vibe.http.client : HTTPClientResponse;
import vibe.stream.operations : readAllUTF8;

interface TelegramUpdateObject {
  int id() const;
  TelegramMessage message() const;
}

interface TelegramMessage {
  TelegramChat from() const;
  TelegramChat chat() const;
  string text() const;
}

interface TelegramChat {
  string chatName() const;
  int chatId() const;
}

TelegramUpdateObject[] getTelegramUpdates(HTTPClientResponse response) {
  if (response.statusCode != 200) {
    throw new Exception(format("getUpdates failed. Status code: %i %s", response.statusCode, response.bodyReader.readAllUTF8()));
  }
  Json jsonResponse;
  try {
    jsonResponse = response.readJson();
  } catch (Exception ignored) {
    throw new Exception(format("getTelegramUpdates failed. Invalid JSON: %s", response.bodyReader.readAllUTF8()));
  }
  if (!jsonResponse.ok.to!bool) {
    throw new Exception(format("getTelegramUpdates failed. Server error: %s", jsonResponse.description.to!string));
  }

  TelegramUpdateObject[] result;
  foreach (Json item; jsonResponse.result) {
    result ~= new TelegramUpdateObjectImpl(item);
  }

  return result;
}

private class TelegramUpdateObjectImpl : TelegramUpdateObject {
  this(const(Json) value) {
    json_ = value;
  }

  int id() const {
    if (json_.update_id.type != Json.Type.int_) {
      throw new Exception("Invalid Telegram Update object: no message");
    }
    return json_.update_id.to!int;
  }

  TelegramMessage message() const {
    if (json_.message.type != Json.Type.object) {
      throw new Exception("Invalid Telegram Update object: no message");
    }
    return new TelegramMessageImpl(json_.message);
  }

  private const(Json) json_;
}

private class TelegramMessageImpl : TelegramMessage {
  this(const(Json) json) {
    json_ = json;
  }

  TelegramChat from() const {
    if (json_.from.type != Json.Type.object) {
      throw new Exception("Invalid Telegram Message: no from field");
    }
    return new TelegramChatImpl(json_.from);
  }

  TelegramChat chat() const {
    if (json_.chat.type != Json.Type.object) {
      throw new Exception("Invalid Telegram Message: no chat field");
    }
    return new TelegramChatImpl(json_.chat);
  }

  string text() const {
    return json_.text.type == Json.Type.string ? json_.text.to!string : "";
  }

  private const(Json) json_;
}

private class TelegramChatImpl : TelegramChat {
  this(const(Json) json) {
    json_ = json;
  }

  string chatName() const {
    if (json_.title.type == Json.Type.string) {
      return json_.title.to!string;
    }

    if (json_.username.type == Json.Type.string) {
      return json_.username.to!string;
    }

    if (json_.first_name.type != Json.Type.string) {
      throw new Exception("Invalid Telegram Chat: no title/username/first_name");
    }

    if (json_.last_name.type != Json.Type.string) {
      return json_.first_name.to!string;
    }

    return json_.first_name.to!string ~ " " ~ json_.last_name.to!string;
  }

  int chatId() const {
    return json_.id.to!int;
  }

  private const(Json) json_;
}
