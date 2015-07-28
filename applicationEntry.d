import std.stdio;
import app;

class RealApp : App {
  void start() {}
}

void main()
{
  startApp(new RealApp);
}
