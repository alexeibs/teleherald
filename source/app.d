interface App {
  void start();
}

void startApp(App app) {
  app.start();
}

class TestApp : App {
  static bool started = false;

  void start() {
    started = true;
  }
}

unittest {
  import dunit.toolkit;

  startApp(new TestApp);

  assertTrue(TestApp.started);
}