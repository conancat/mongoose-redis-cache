{spawn, exec} = require 'child_process'
sys = require 'util'

printOutput = (process) ->
  process.stdout.on 'data', (data) -> sys.print data
  process.stderr.on 'data', (data) -> sys.print data

watchJS = (service) ->
  coffee = exec 'coffee -cwb -o ./ src/'
  printOutput(coffee)

task 'watch', 'Watches all coffeescript files in all services for changes', ->
  watchJS()
