define([], function() {

  function Server(RequestClass, baseUrl) {
    this._RequestClass = RequestClass;
    this._baseUrl = baseUrl;
  }

  Server.prototype.get = function(query, callback) {
    return this._sendRequest('GET', query, null, callback);
  };

  Server.prototype.post = function(query, postData, callback) {
    return this._sendRequest('POST', query, postData, callback);
  };

  Server.prototype._sendRequest = function(requestType, query, postData, callback) {
    var request = new this._RequestClass();
    request.open(requestType, this._baseUrl + '/' + query, true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.onreadystatechange = this._onReadyStateChange.bind(this, request, callback);
    if (postData === null) {
      request.send();
    } else {
      request.send(postData);
    }
    return request;
  };

  Server.prototype._onReadyStateChange = function(request, callback) {
    if (request.readyState != 4 || callback === undefined) {
      return;
    }
    if (request.status != 200) {
      callback(null, request.statusText);

    } else {
      var response;
      try {
        response = JSON.parse(request.responseText);

      } catch (e) {
        callback(null, e.toString());
        return;
      }
      callback(response);
    }
  };

  return {
    create: function(RequestClass, baseUrl) {
      return new Server(RequestClass, baseUrl);
    }
  };
});
