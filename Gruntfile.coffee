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
      buildSync:
        options:
          bare: false
        files:   
          'lib/Backbone.cruds.sync.js': 'src/Backbone.cruds.sync.coffee.md'
      test:
        options:
          bare: true
        files:
          'test/browser/js/test.raw.js': 'test/browser/coffee/test.raw.coffee'
          'test/browser/js/test.backbone.cruds.js': 'test/browser/coffee/test.backbone.cruds.coffee'
          'test/express.js': 'test/express.coffee'
          'test/browser/js/Backbone.cruds.sync.js': 'src/Backbone.cruds.sync.coffee.md'

    mochaTest:
      test:
        options:
          globals: ['should']
          ui: 'bdd'
          reporter: 'list'
          require: 'coffee-script'
        src: ['test/server/*.coffee']

    shell:
      cpsync:
        command: 'cp lib/Backbone.cruds.sync.js test/browser/js/Backbone.cruds.sync.js'

    watch:
      cruds: 
        files: ['src/cruds.coffee.md']
        tasks: ['coffee:build']
        options:
          spawn: true
      sync:
        files: ['src/Backbone.cruds.sync.coffee.md']
        tasks: ['coffee:buildSync', 'shell:cpsync']
        options:
          spawn: true
      tests:
        files: ['test/browser/coffee/*.coffee']
        tasks: ['coffee:test']
        options:
          spawn: false


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-shell-spawn'
  grunt.loadNpmTasks 'saucelabs-mocha'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  for key of grunt.file.readJSON("package.json").devDependencies
    if key isnt "grunt" and key.indexOf("grunt") is 0
      grunt.loadNpmTasks(key)
  
  grunt.registerTask 'drop-mongodb', 'drop the database', ->
    mongoose = require "mongoose"
    done = @async()
    mongoose.connect "mongodb://localhost:27017/cruds", ->
      mongoose.connection.db.dropDatabase ->
        mongoose.disconnect ->
          done()


  grunt.registerTask 'test', ['coffee:build', 'coffee:buildSync', 'coffee:test', 'shell:cpsync', 'drop-mongodb', 'mochaTest']
  grunt.registerTask 'default', ['coffee:build', 'coffee:test']
  grunt.registerTask 'dist', ['coffee:build']

