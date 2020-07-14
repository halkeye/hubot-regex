/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
module.exports = function(grunt){
  'use strict';

  // Project configuration.
  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),
    eslint: {target: ['src/scripts/**/*.js', 'src/test/**/*.js']},
    simplemocha: {
      all: {
        src: [
          'node_modules/should/lib/should.js',
          'src/test/**/*.js'
        ],
        options: {
          globals: ['should'],
          timeout: 3000,
          bail: true,
          ignoreLeaks: false,
          ui: 'bdd',
          reporter: 'tap'
        }
      }
    },
    watch: {
      jsLib: {
        files: ['src/scripts/**/*.js'],
        tasks: ['eslint:scripts', 'simplemocha']
      },
      jsTest: {
        files: ['src/test/**/*.js'],
        tasks: ['eslint:test', 'simplemocha']
      },
    },
  });

  // plugins.
  grunt.loadNpmTasks('grunt-simple-mocha');
  grunt.loadNpmTasks('grunt-eslint');
  grunt.loadNpmTasks('grunt-contrib-watch');

  // tasks.
  grunt.registerTask('compile', [
    'eslint',
  ]);

  return grunt.registerTask('default', [
    'compile',
    'simplemocha'
  ]);
};

