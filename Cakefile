exec = require('child_process').exec

task 'build', 'build everything', () ->
  
  console.log 'compile'
  exec "coffee -o lib/ -c src/crud.coffee"

  console.log 'create documentation'
  exec "docco src/crud.coffee"