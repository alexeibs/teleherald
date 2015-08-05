/* global describe, it, expect */
/* global jasmine, beforeEach, afterEach, spyOn */

define(['scripts/data-model'], function(DataModel) {

  function createFakeServer() {
    var getCallback = null;
    var server = {
      get: function(query, callback) {
        getCallback = callback;
      },
      sendGetResponse: function(response, error) {
        getCallback(response, error);
      },
      post: jasmine.createSpy('post')
    };
    spyOn(server, 'get').and.callThrough();
    return server;
  }

  describe('data-model.js', function() {
    beforeEach(function() {
      jasmine.clock().install();
    });

    afterEach(function() {
      jasmine.clock().uninstall();
    });

    it('Poll server by timer', function() {
      var server = createFakeServer();
      var view = jasmine.createSpyObj('ActivationView', ['setState']);
      var dataModel = DataModel.create(server, 100);
      dataModel.addActivationView(view);

      expect(view.setState.calls.count()).toBe(1);
      expect(view.setState.calls.mostRecent().args).toEqual([{data: []}]);
      expect(dataModel.getActivationList()).toEqual([]);
      expect(server.get.calls.count()).toBe(0);

      jasmine.clock().tick(101);
      expect(dataModel.getActivationList()).toEqual([]);
      expect(server.get.calls.count()).toBe(1);
      expect(server.get.calls.mostRecent().args).toEqual(['activationList', jasmine.any(Function)]);

      jasmine.clock().tick(100);
      expect(dataModel.getActivationList()).toEqual([]);
      expect(server.get.calls.count()).toBe(1);

      var testData = [{token: 'tok1', chatName: 'Chat #11', code: '123456'}];
      server.sendGetResponse(testData);
      expect(dataModel.getActivationList()).toEqual(testData);
      expect(view.setState.calls.count()).toBe(2);
      expect(view.setState.calls.mostRecent().args).toEqual([{data: testData}]);

      jasmine.clock().tick(100);
      expect(dataModel.getActivationList()).toEqual(testData);
      expect(server.get.calls.count()).toBe(2);
      expect(server.get.calls.mostRecent().args).toEqual(['activationList', jasmine.any(Function)]);

      spyOn(console, 'error');
      server.sendGetResponse(null, 'invalid request');
      expect(console.error).toHaveBeenCalledWith('_takeActivationList failed: ', 'invalid request');
      expect(view.setState.calls.count()).toBe(2);
      expect(dataModel.getActivationList()).toEqual(testData);

      dataModel.addNewChat('New chat');
      expect(server.post.calls.count()).toBe(1);
      expect(server.post.calls.mostRecent().args).toEqual(['activationList', {chatName: 'New chat'}]);

      dataModel.stopPolling();
    });
  });
});
