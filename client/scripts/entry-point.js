define(['scripts/server', 'scripts/data-model', 'scripts/activation-view.jsx'],
  function(Server, DataModel, ActivationView) {
    return {
      run: function(contentPanel) {
        var server = Server.create(XMLHttpRequest, location.pathname);
        var model = DataModel.create(server, 2000);
        var view = ActivationView.create(contentPanel, model.addNewChat.bind(model));
        model.addActivationView(view);
      }
    };
  }
);
