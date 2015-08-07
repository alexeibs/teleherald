define(['vendor/react/react'], function(React) {

  var ActivationTableHeader = React.createClass({
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

  var ActivationTableEntry = React.createClass({
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

  var ActivationTable = React.createClass({
    render: function() {
      var entries = this.props.data.map(function(entry) {
        return (
          <ActivationTableEntry key={entry.token} token={entry.token} chatName={entry.chatName} code={entry.code} />
        );
      });

      return (
        <table className="activation-view">
          <ActivationTableHeader />
          {entries}
        </table>
      );
    }
  });

  var ActivationForm = React.createClass({
    handleSubmit: function(e) {
      e.preventDefault();
      var chatName = React.findDOMNode(this.refs.chatName).value.trim();
      this.props.onNewChatName(chatName);
    },
    render: function() {
      return (
        <form className="activation-view" onSubmit={this.handleSubmit}>
          <input name="chatName" type="text" placeholder="Chat name" ref="chatName" />&nbsp;
          <button type="submit">Add new chat</button>
        </form>
      );
    }
  });

  var ActivationView = React.createClass({
    getInitialState: function() {
      return {data: []};
    },
    render: function() {
      return (
        <div>
          <ActivationForm onNewChatName={this.props.onNewChatName} />
          <br />
          <ActivationTable data={this.state.data} />
        </div>
      );
    }
  });

  return {
    create: function(parent, onNewChatName) {
      return React.render(<ActivationView onNewChatName={onNewChatName} />, parent);
    }
  };
});
