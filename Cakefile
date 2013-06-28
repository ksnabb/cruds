exec = require('child_process').exec

task 'build', 'build everything', () ->
  
  console.log 'compile'
  exec "coffee -o lib/ -c -b src/crud.litcoffee"

  console.log 'create documentation'
  exec "docco src/crud.litcoffee"


task 'test', 'run all the tests', () -> 
  Mocha = require 'mocha'
  path = require 'path'
  mocha = new Mocha

  console.log 'compile the tests'
  exec 'coffee -o test/ -c test/*.coffee'

  console.log 'Add all files to be tested'
  fs.readdirSync('test').filter (file) ->
    #Only keep the .js files
    return file.substr(-3) == '.js'
  .forEach (file) ->
    #Use the method "addFile" to add the file to mocha
    mocha.addFile path.join('test', file)

  #Now, you can run the tests.
  mocha.run (failures) ->
    process.exit failures
