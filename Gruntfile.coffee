path = require "path"

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
        options:
          bare: true
        files:
          'test/browser/js/test.js': 'test/browser/coffee/test.coffee'
          'test/express.js': 'test/express.coffee'

    mochaTest:
      test:
        options:
          globals: ['should']
          ui: 'bdd'
          reporter: 'list'
          require: 'coffee-script'
        src: ['test/server/*.coffee']

    shell:
      server:
        command: 'PORT=3000 node ./test/express.js'
        options:
          async: true
  
    mocha_phantomjs:
      test:
        options:
          reported: "list"
          urls: ['http://localhost:3000/test.html']


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-shell-spawn'
  grunt.loadNpmTasks 'grunt-mocha-phantomjs'
  grunt.registerTask 'drop-mongodb', 'drop the database', ->
    mongoose = require "mongoose"
    done = @async()
    mongoose.connect "mongodb://localhost:27017/cruds", ->
      mongoose.connection.db.dropDatabase ->
        mongoose.disconnect ->
          done()


  grunt.registerTask 'test', ['coffee:build', 'coffee:test', 'drop-mongodb', 'mochaTest', 'shell:server', 'drop-mongodb', 'mocha_phantomjs', 'shell:server:kill']
  grunt.registerTask 'default', ['coffee:build']
