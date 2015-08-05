/* global module */
module.exports = function(config) {
  config.set({
    basePath: './',
    frameworks: ['jasmine', 'requirejs'],
    files: [
      'specs/karma-entry.js',
      {pattern: 'scripts/**/*.js', included: false},
      {pattern: 'specs/**/*.js', included: false},
      {pattern: 'vendor/**/*.js', included: false}
    ],
    preprocessors: {
      'scripts/**/*.js': ['coverage']
    },
    reporters: ['progress', 'coverage'],
    coverageReporter: {
      type : 'html',
      dir : 'coverage/'
    }
  });
};
