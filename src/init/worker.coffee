iron_worker = require 'iron_worker'

module.exports.name = 'worker'

module.exports.attach = ->
  @worker = new iron_worker.Client @config.get('ironworker:auth')

module.exports.init = (done) ->
  done()