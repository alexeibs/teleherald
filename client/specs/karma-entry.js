/* global requirejs */
(function() {
  function endsWith(string, suffix) {
    return string.indexOf(suffix, string.length - suffix.length) !== -1;
  }
  var tests = [];
  for (var file in window.__karma__.files) {
    if (window.__karma__.files.hasOwnProperty(file)) {
      var matches = file.match(/\/base\/(.+)\.js$/);
      if (matches !== null && !endsWith(matches[1], 'entry-point')) {
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
