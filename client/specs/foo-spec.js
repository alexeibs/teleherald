/* global describe, it, expect */

define(['scripts/foo.jsx'], function(foo) {
  describe('foo.jsx', function() {
    it('Test #1', function() {

      var testDiv = document.createElement('div');
      document.body.appendChild(testDiv);
      var fooObject = foo.create(testDiv);
      fooObject.setState({title: 'Custom Title'});

      var reactNode = testDiv.querySelector('h1');
      expect(reactNode).toBeDefined();
      expect(reactNode.innerHTML).toEqual('Custom Title');

      document.body.removeChild(testDiv);
    });
  });
});
