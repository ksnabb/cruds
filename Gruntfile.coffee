module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      build:
        options:
          bare: true
        files:
          'lib/cruds.js': 'src/cruds.coffee.md'
      test:
        files:
          'test/browser/js/test.js': 'test/browser/coffee/test.coffee'

    mochaTest:
      test:
        options:
          globals: ['should']
          ui: 'bdd'
          reporter: 'list'
          require: 'coffee-script'
        src: ['test/server/*.coffee']

    mocha:
      test:
        src: ['test/browser/*.html']
        reporter: 'list'

    watch:
      coffee: 
        files: ['src/cruds.coffee.md']
        tasks: ['coffee:build']
        options:
          spawn: false


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-mocha'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'test', ['coffee:test', 'mochaTest', 'mocha']
  grunt.registerTask 'default', ['coffee:build']