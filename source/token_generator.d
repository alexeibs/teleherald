import std.conv;
import std.digest.sha;
import std.traits;

interface RandomNumberGenerator {
  uint getNumber();
}

interface TokenGenerator {
  uint getActivationCode();
  void forgetActivationCode(uint code);
  string getToken();
  void forgetToken(string token);
}

TokenGenerator createTokenGenerator(RandomNumberGenerator rng) {
  return new TokenGeneratorImpl(rng);
}

private class TokenGeneratorImpl : TokenGenerator {
  this(RandomNumberGenerator rng) {
    activationCodeGenerator_ = new UniqueLimitedNumberGenerator!uint(rng, 100000, 1000000);
    tokenGenerator_ = new UniqueTokenGenerator!string(rng);
  }

  uint getActivationCode() {
    return activationCodeGenerator_.get();
  }

  void forgetActivationCode(uint code) {
    return activationCodeGenerator_.forget(code);
  }

  string getToken() {
    return tokenGenerator_.get();
  }

  void forgetToken(string token) {
    tokenGenerator_.forget(token);
  }

  UniqueLimitedNumberGenerator!uint activationCodeGenerator_;
  UniqueTokenGenerator!string tokenGenerator_;
}

private T tokenify(T)(uint n) {
  return to!T(n);
}

private string tokenify(T: string)(uint n) {
  return toHexString(digest!SHA256([n])).dup;
}

private class UniqueTokenGenerator(T) if (isIntegral!T || is(T == string)) {
  this(RandomNumberGenerator rng) {
    rng_ = rng;
  }

  final T get() {
    T token;
    do {
      token = tokenify!T(generate());
    } while (token in inUse_);
    inUse_[token] = true;
    return token;
  }

  final void forget(T token) {
    inUse_.remove(token);
  }

  protected uint generate() {
    return rng_.getNumber();
  }

  private bool[T] inUse_;
  private RandomNumberGenerator rng_;
}

private class UniqueLimitedNumberGenerator(T) : UniqueTokenGenerator!T if (isIntegral!T) {
  this(RandomNumberGenerator rng, T min, T max) {
    super(rng);
    base = to!uint(max - min);
    offset = min;
  }

  protected override uint generate() {
    return to!T(rng_.getNumber() % base) + offset;
  }

  private uint base;
  private T offset;
}

unittest {
  import dunit.toolkit;

  class FakeRNG : RandomNumberGenerator {
    this() {
      setNext([1]);
    }

    final void setNext(uint[] numbers) {
      assert(numbers.length > 0);
      next = numbers.dup;
      current = 0;
    }

    override uint getNumber() {
      uint n = next[current];
      current = (current + 1) % next.length;
      return n;
    }

    private uint[] next;
    private int current;
  }
  auto rng = new FakeRNG;
  auto generator = createTokenGenerator(rng);

  rng.setNext([899999, 899999, 900000]);

  assertEqual(generator.getActivationCode(), 999999);
  assertEqual(generator.getActivationCode(), 100000);

  generator.forgetActivationCode(999999);
  assertEqual(generator.getActivationCode(), 999999);

  rng.setNext([0, 0, 1]);
  string HASH_0 = "DF3F619804A92FDB4057192DC43DD748EA778ADC52BC498CE80524C014B81119"; // sha256(0)
  string HASH_1 = "67ABDD721024F0FF4E0B3F4C2FC13BC5BAD42D0B7851D456D88D203D15AAA450"; // sha256(1)

  assertEqual(tokenify!string(0), HASH_0);
  assertEqual(tokenify!string(1), HASH_1);

  assertEqual(generator.getToken(), HASH_0);
  assertEqual(generator.getToken(), HASH_1);

  generator.forgetToken(HASH_0);
  assertEqual(generator.getToken(), HASH_0);
}