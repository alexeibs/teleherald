/* global module */
module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
      files: ['gruntfile.js', 'scripts/**/*.js', 'specs/**/*.js', '!scripts/**/*.jsx.js'],
      options: {
        jshintrc: '.jshintrc'
      }
    },
    jscs: {
      src: ['gruntfile.js', 'scripts/**/*.js', 'specs/**/*.js', 'scripts/**/*.jsx', '!scripts/**/*.jsx.js'],
      options: {
        config: '.jscsrc'
      }
    },
    react: {
      all: {
        options: {
          sourceMap: true
        },
        files: [
          {
            expand: true,
            cwd: 'scripts/',
            src: ['**/*.jsx'],
            dest: 'scripts/',
            ext: '.jsx.js'
          }
        ]
      }
    },
    jasmine: {
      src: ['scripts/**/*.js'],
      options: {
        specs: 'specs/**/*-spec.js',
        keepRunner: true,
        template: require('grunt-template-jasmine-requirejs'),
        templateOptions: {
          requireConfig: {
            callback: function() {
              require(['vendor/es5-shim/es5-shim']);
            }
          }
        }
      }
    },
    clean: {
      all: {
        src: ['../public'],
        options: {
          force: true
        }
      }
    },
    copy: {
      scripts: {
        files: [{
          expand: true,
          cwd: 'scripts/',
          src: ['**/*.js'],
          dest: '../public/scripts'
        }]
      },
      styles: {
        files: [{
          expand: true,
          cwd: 'styles/',
          src: ['**/*.css'],
          dest: '../public/styles'
        }]
      },
      vendor: {
        files: [{
          expand: true,
          cwd: 'vendor/',
          src: ['**/*.js'],
          dest: '../public/vendor'
        }]
      }
    },
    watch: {
      options: {
        livereload: true,
      },
      react: {
        files: ['scripts/**/*.jsx'],
        tasks: ['react']
      },
      scripts: {
        files: ['vendor/**/*.js', 'scripts/**/*.js', 'specs/**/*-spec.js'],
        tasks: ['tests']
      },
      others: {
        files: ['test.html', 'styles/**/*.css'],
        tasks: []
      },
      self: {
        files: ['gruntfile.js'],
        tasks: ['react'] // react will cause tests then
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-jscs');
  grunt.loadNpmTasks('grunt-contrib-jasmine');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-react');

  grunt.registerTask('tests', ['jshint', 'jscs', 'jasmine']);
  grunt.registerTask('default', ['react', 'tests', 'clean', 'copy']);
};
