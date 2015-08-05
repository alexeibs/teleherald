/* global describe, it, expect */
/* global jasmine */

define(['scripts/server'], function(Server) {

  function FakeRequest() {}
  FakeRequest.prototype.setRequestHeader = jasmine.createSpy('setRequestHeader');
  FakeRequest.prototype.open = jasmine.createSpy('open');
  FakeRequest.prototype.send = jasmine.createSpy('send');

  describe('server.js', function() {
    it('Successful GET request', function() {
      var testCallback = jasmine.createSpy('testCallback');
      var server = Server.create(FakeRequest, '/base/path');
      var request = server.get('test', testCallback);

      expect(request.setRequestHeader).toHaveBeenCalledWith('Content-Type', 'application/json');
      expect(request.onreadystatechange).toEqual(jasmine.any(Function));
      expect(request.open).toHaveBeenCalledWith('GET', '/base/path/test', true);
      expect(request.send).toHaveBeenCalledWith();

      request.readyState = 3;
      request.onreadystatechange();
      expect(testCallback).not.toHaveBeenCalled();

      request.readyState = 4;
      request.status = 200;
      request.responseText = '{"result": "Ok!"}';
      request.onreadystatechange();
      expect(testCallback).toHaveBeenCalledWith({'result': 'Ok!'});
    });

    it('Failing GET request', function() {
      var testCallback = jasmine.createSpy('testCallback');
      var server = Server.create(FakeRequest, '/base/path');
      var request = server.get('test', testCallback);

      request.readyState = 4;
      request.status = 500;
      request.statusText = 'test error description';
      request.onreadystatechange();
      expect(testCallback).toHaveBeenCalledWith(null, 'test error description');
    });

    it('POST request without callback', function() {
      var server = Server.create(FakeRequest, '/base/path');
      var request = server.post('test', '{"test": 10}');

      expect(request.open).toHaveBeenCalledWith('POST', '/base/path/test', true);
      expect(request.send).toHaveBeenCalledWith('{"test": 10}');
    });
  });
});
