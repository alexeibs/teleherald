/* global requirejs */
(function() {
  var tests = [];
  for (var file in window.__karma__.files) {
    if (window.__karma__.files.hasOwnProperty(file)) {
      var matches = file.match(/\/base\/(.+-spec)\.js$/);
      if (matches !== null) {
        tests.push(matches[1]);
      }
    }
  }
  requirejs.config({
    baseUrl: '/base'
  });
  require(tests, function() {
    window.__karma__.start();
  });
})();
