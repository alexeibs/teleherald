define(['vendor/react/react'], function(React) {

  var Foo = React.createClass({
    getInitialState: function() {
      return {
        title: 'Hello'
      };
    },
    render: function() {
      return (
        <h1>{this.state.title}</h1>
      );
    }
  });

  function createFoo(parent) {
    return React.render(<Foo />, parent);
  }

  return {
    create: createFoo
  };
});
