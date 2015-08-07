define(['scripts/server', 'scripts/data-model', 'scripts/activation-view.jsx'],
  function(Server, DataModel, ActivationView) {
    return {
      run: function(params) {
        var server = Server.create(XMLHttpRequest, params.requestBasePath);
        var model = DataModel.create(server, 2000);
        var view = ActivationView.create(params.viewContainer, model.addNewChat.bind(model));
        model.addActivationView(view);
      }
    };
  }
);
