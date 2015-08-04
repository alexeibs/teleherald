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
      vendor: {
        files: ['vendor/**/*.js'],
        tasks: ['tests', 'copy:vendor']
      },
      react: {
        files: ['scripts/**/*.jsx'],
        tasks: ['react']
      },
      scripts: {
        files: ['scripts/**/*.js'],
        tasks: ['jshint', 'jscs', 'jasmine', 'copy:scripts']
      },
      styles: {
        files: ['styles/**/*.css'],
        tasks: ['tests', 'copy:styles']
      },
      entry: {
        files: ['test.html'],
        tasks: []
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

  grunt.registerTask('tests', ['jshint', 'jscs', 'react', 'jasmine']);
  grunt.registerTask('default', ['tests', 'clean', 'copy']);
};
