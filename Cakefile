exec = require('child_process').exec

task 'build', 'build everything', () ->
  
  console.log 'compile'
  exec "coffee -o lib/ -c -b src/crud.litcoffee"

  console.log 'create documentation'
  exec "docco src/crud.coffee"