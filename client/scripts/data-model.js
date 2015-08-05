define([], function() {

  function DataModel(server, pollInterval) {
    this._activationList = [];
    this._activationViews = [];

    this._waitingForResponse = false;
    this._server = server;
    this._timer = setInterval(this._askForActivationList.bind(this), pollInterval);
  }

  DataModel.prototype.getActivationList = function() {
    return this._activationList;
  };

  DataModel.prototype.stopPolling = function() {
    clearInterval(this._timer);
  };

  DataModel.prototype.addActivationView = function(view) {
    this._activationViews.push(view);
    this._updateActivationView(view);
  };

  DataModel.prototype.addNewChat = function(chatName) {
    this._server.post('activationList', {}, {chatName: chatName});
  };

  DataModel.prototype._askForActivationList = function() {
    if (this._waitingForResponse) {
      return;
    }
    this._waitingForResponse = true;
    this._server.get('activationList', {}, this._takeActivationList.bind(this));
  };

  DataModel.prototype._takeActivationList = function(data, error) {
    this._waitingForResponse = false;
    if (error !== undefined) {
      console.error('_takeActivationList failed: ', error);
    } else {
      this._activationList = data;
      this._updateActivationViews();
    }
  };

  DataModel.prototype._updateActivationViews = function() {
    for (var i = 0, imax = this._activationViews.length; i < imax; ++i) {
      this._updateActivationView(this._activationViews[i]);
    }
  };

  DataModel.prototype._updateActivationView = function(view) {
    view.setState({data: this._activationList});
  };

  return {
    create: function(server, pollInterval) {
      return new DataModel(server, pollInterval);
    }
  };
});
