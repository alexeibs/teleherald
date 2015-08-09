import std.format : format;

import vibe.data.json : Json, parseJson;
import vibe.http.client : HTTPClientResponse;

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

interface JsonResponse {
  int statusCode() const;
  string rawResponse();
  Json json();
}

TelegramUpdateObject[] getTelegramUpdates(JsonResponse response) {
  if (response.statusCode() != 200) {
    throw new Exception(format("getTelegramUpdates failed. Status code: %d, response: %s",
        response.statusCode(), response.rawResponse()));
  }

  Json jsonResponse;
  try {
    jsonResponse = response.json();
  } catch (Exception ignored) {
    throw new Exception(format("getTelegramUpdates failed. Invalid JSON: %s", response.rawResponse()));
  }

  if (jsonResponse.type != Json.Type.object) {
    throw new Exception("getTelegramUpdates failed. Response is not a JSON object");
  }
  if (jsonResponse.ok.type != Json.Type.bool_) {
    throw new Exception("getTelegramUpdates failed. Format error: no ok field");
  }
  if (!jsonResponse.ok) {
    if (jsonResponse.description.type != Json.Type.string) {
      throw new Exception("getTelegramUpdates failed. Unknown Telegram error without description");
    }
    throw new Exception(format("getTelegramUpdates failed. Telegram error: %s", jsonResponse.description.to!string));
  }

  if (jsonResponse.result.type != Json.Type.array) {
    throw new Exception("getTelegramUpdates failed. Format error: result is not an array");
  }
  try {
    TelegramUpdateObject[] result;
    foreach (Json item; jsonResponse.result) {
      if (item.type != Json.Type.object) {
        throw new Exception("Update is not an object");
      }
      result ~= new TelegramUpdateObjectImpl(item);
    }
    return result;

  } catch (Exception error) {
    throw new Exception(format("getTelegramUpdates failed. Format error: %s", error.msg));
  }
}

private class TelegramUpdateObjectImpl : TelegramUpdateObject {
  this(const(Json) value) {
    json_ = value;
  }

  int id() const {
    if (json_.update_id.type != Json.Type.int_) {
      throw new Exception("Invalid Telegram Update object: no update_id");
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
    if (json_.id.type != Json.Type.int_) {
      throw new Exception("Invalid Telegram Chat: no chatId");
    }
    return json_.id.to!int;
  }

  private const(Json) json_;
}

unittest {
  import dunit.toolkit;

  static class TestResponse : JsonResponse {
    this(int code, string responseBody) {
      code_ = code;
      responseBody_ = responseBody;
    }

    int statusCode() const {
      return code_;
    }

    string rawResponse() {
      return responseBody_;
    }

    Json json() {
      return parseJson(responseBody_);
    }

    private int code_;
    private string responseBody_;
  }

  getTelegramUpdates(new TestResponse(500, "server error"))
      .assertThrow("getTelegramUpdates failed. Status code: 500, response: server error");

  getTelegramUpdates(new TestResponse(200, "invalid json"))
      .assertThrow("getTelegramUpdates failed. Invalid JSON: invalid json");

  getTelegramUpdates(new TestResponse(200, q"{[]}"))
      .assertThrow("getTelegramUpdates failed. Response is not a JSON object");

  getTelegramUpdates(new TestResponse(200, q"{{"okkk": "true"}}"))
      .assertThrow("getTelegramUpdates failed. Format error: no ok field");

  getTelegramUpdates(new TestResponse(200, q"{{"ok": false}}"))
      .assertThrow("getTelegramUpdates failed. Unknown Telegram error without description");
  
  getTelegramUpdates(new TestResponse(200, q"{{"ok": false, "description": "telegram error"}}"))
      .assertThrow("getTelegramUpdates failed. Telegram error: telegram error");

  getTelegramUpdates(new TestResponse(200, q"{{"ok": true}}"))
      .assertThrow("getTelegramUpdates failed. Format error: result is not an array");

  getTelegramUpdates(new TestResponse(200, q"{{"ok": true, "result": [1]}}"))
      .assertThrow("getTelegramUpdates failed. Format error: Update is not an object");

  auto updates = getTelegramUpdates(new TestResponse(200, q"{
    {
      "ok": true,
      "result": [
        {},
        {"update_id": 10},
        {
          "update_id": 11,
          "message": {}
        },
        {
          "update_id": 12,
          "message": {
            "from": {},
            "chat": {
              "id": 100
            },
            "text": "hello"
          }
        },
        {
          "update_id": 13,
          "message": {
            "from": {
              "id": 101,
              "username": "user"
            },
            "chat": {
              "id": 102,
              "title": "test chat"
            },
            "text": "ok"
          }
        },
        {
          "update_id": 14,
          "message": {
            "from": {
              "id": 103,
              "first_name": "Bob"
            },
            "chat": {
              "id": 104,
              "first_name": "John",
              "last_name": "Smit"
            },
            "text": "some text"
          }
        }
      ]
    }
  }"));

  updates.length.assertEqual(6);

  updates[0].id().assertThrow("Invalid Telegram Update object: no update_id");
  updates[0].message().assertThrow("Invalid Telegram Update object: no message");

  updates[1].id().assertEqual(10);
    updates[1].message().assertThrow("Invalid Telegram Update object: no message");

  auto message2 = updates[2].message();
  message2.from().assertThrow("Invalid Telegram Message: no from field");
  message2.chat().assertThrow("Invalid Telegram Message: no chat field");
  message2.text().assertEqual("");

  auto message3 = updates[3].message();
  message3.from().chatId().assertThrow("Invalid Telegram Chat: no chatId");
  message3.from().chatName().assertThrow("Invalid Telegram Chat: no title/username/first_name");
  message3.chat().chatId().assertEqual(100);
  message3.chat().chatName().assertThrow("Invalid Telegram Chat: no title/username/first_name");
  message3.text().assertEqual("hello");

  auto message4 = updates[4].message();
  message4.from().chatId().assertEqual(101);
  message4.from().chatName().assertEqual("user");
  message4.chat().chatId().assertEqual(102);
  message4.chat().chatName().assertEqual("test chat");
  message4.text().assertEqual("ok");

  auto message5 = updates[5].message();
  message5.from().chatId().assertEqual(103);
  message5.from().chatName().assertEqual("Bob");
  message5.chat().chatId().assertEqual(104);
  message5.chat().chatName().assertEqual("John Smit");
  message5.text().assertEqual("some text");
}