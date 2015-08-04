/* global describe, it, expect */

define(['scripts/activation'], function(activation) {
  describe('activation.js', function() {
    it('Test #1', function() {
      var obj = new activation.TestClass(42);
      expect(obj.value()).toBe(42);
    });
  });
});
