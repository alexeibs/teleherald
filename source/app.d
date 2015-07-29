interface App {
  void start();
}

void startApp(App app) {
  app.start();
}

unittest {
  import dunit.toolkit;

  static class TestApp : App {
    static bool started = false;

    void start() {
      started = true;
    }
  }

  startApp(new TestApp);

  assertTrue(TestApp.started);
}