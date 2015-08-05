define(['vendor/react/react'], function(React) {

  var ActivationViewHeader = React.createClass({
    render: function() {
      return (
        <thead>
          <tr>
            <th className="col1">Token</th>
            <th className="col2">Chat name</th>
            <th className="col3">Activation code</th>
          </tr>
        </thead>
      );
    }
  });

  var ActivationViewEntry = React.createClass({
    render: function() {
      return (
        <tr>
          <td className="col1">{this.props.token}</td>
          <td className="col2">{this.props.chatName}</td>
          <td className="col3">{this.props.code}</td>
        </tr>
      );
    }
  });

  var ActivationView = React.createClass({
    getInitialState: function() {
      return {data: []};
    },
    render: function() {
      var entries = this.state.data.map(function(entry) {
        return (
          <ActivationViewEntry key={entry.token} token={entry.token} chatName={entry.chatName} code={entry.code} />
        );
      });

      return (
        <table className="activation-view">
          <ActivationViewHeader />
          {entries}
        </table>
      );
    }
  });

  return {
    create: function createActivationView(parent) {
      return React.render(<ActivationView />, parent);
    }
  };
});
