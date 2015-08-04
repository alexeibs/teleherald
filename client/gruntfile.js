/* global module */
module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
      files: ['gruntfile.js', 'scripts/**/*.js', 'specs/**/*.js'],
      options: {
        jshintrc: '.jshintrc'
      }
    },
    jscs: {
      src: ['gruntfile.js', 'scripts/**/*.js', 'specs/**/*.js'],
      options: {
        config: '.jscsrc'
      }
    },
    jasmine: {
      src: ['scripts/**/*.js'],
      options: {
        specs: 'specs/**/*-spec.js',
        keepRunner: true,
        template: require('grunt-template-jasmine-requirejs')
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
      scripts: {
        files: ['scripts/**/*.js'],
        tasks: ['tests', 'copy:scripts']
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

  grunt.registerTask('tests', ['jshint', 'jscs', 'jasmine']);
  grunt.registerTask('default', ['tests', 'clean', 'copy']);
};
