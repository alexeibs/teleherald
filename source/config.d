import std.json;

interface Config {
  string appToken();
  string activatorPath();
}

Config parseConfig(string json) {
  return new ConfigImpl(json);
}

private class ConfigImpl  : Config {
  this(string json) {
    try {
      auto jsonTree = parseJSON(json);

      if (jsonTree.type == JSON_TYPE.OBJECT) {
        appToken_ = readString(jsonTree.object, "appToken");
        activatorPath_ = readString(jsonTree.object, "activatorPath");
      }
    } catch (JSONException e) {}
  }

  private string readString(JSONValue[string] object, string key) {
    auto value = key in object;
    return value && value.type == JSON_TYPE.STRING ? value.str : "";
  }

  string appToken() const {
    return appToken_;
  }

  string activatorPath() const {
    return activatorPath_;
  }

  private string appToken_;
  private string activatorPath_;
}

unittest {
  import dunit.toolkit;

  void testJson(string token, string path, string json) {
    auto config = parseConfig(json);
    assertEqual(config.appToken(), token);
    assertEqual(config.activatorPath(), path);
  }

  testJson("token", "path", q"{{
    "appToken": "token",
    "activatorPath": "path"
  }}");

  testJson("", "", q"{invalid JSON}");

  testJson("", "", q"{[]}");

  testJson("42", "", q"{{
    "appToken": "42"
  }}");

  testJson("", "", q"{{
    "appToken": 42,
    "activatorPath": true
  }}");

  testJson("", "path", q"{{
    "activatorPath": "path"
  }}");
}