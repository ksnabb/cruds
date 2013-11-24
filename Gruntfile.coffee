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
        options:
          run: true
          reporter: "List"

    watch:
      main: 
        files: ['src/cruds.coffee.md', 'test/browser/*.html', 'test/server/*.coffee']
        tasks: ['coffee:build', 'coffee:test', 'mochaTest', 'mocha']
        options:
          spawn: false


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-mocha'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'drop-mongodb', 'drop the database', ->
    mongoose = require "mongoose"
    done = @async()
    mongoose.connect "mongodb://localhost:27017/test", ->
      mongoose.connection.db.dropDatabase ->
        mongoose.disconnect ->
          done()


  grunt.registerTask 'test', ['drop-mongodb','coffee:build', 'coffee:test', 'mochaTest', 'mocha']
  grunt.registerTask 'default', ['coffee:build']