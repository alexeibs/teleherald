/* global module */
module.exports = function(config) {
  config.set({
    basePath: './',
    frameworks: ['jasmine', 'requirejs'],
    files: [
      'specs/karma-entry.js',
      {pattern: 'scripts/**', included: false},
      {pattern: 'specs/**', included: false},
      {pattern: 'vendor/**', included: false}
    ],
    preprocessors: {
      'scripts/**/*.js': ['coverage']
    },
    reporters: ['coverage'],
    coverageReporter: {
      type : 'html',
      dir : 'coverage/'
    }
  });
};
