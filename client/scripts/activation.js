define([], function() {

  function TestClass(value) {
    this._value = value;
  }

  TestClass.prototype.value = function() {
    return this._value;
  };

  return {
    TestClass: TestClass
  };

});
