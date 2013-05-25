async = require 'async'
indexden = require 'indexden'

module.exports.name = 'index'

module.exports.attach = ->
  @index = indexden.connect @config.get('indextank:config')
  @index.indexes ?= {}

module.exports.init = (done) ->
  self = this
  indexes = @config.get('indextank:indexes')

  async.each Object.keys(indexes), (key, eachCallback) ->
    index = indexes[key]

    self.index.createIndex index.index, index.public_search, (err, result) ->
      if err
        eachCallback(err)
      else
        self.index.indexes[key] = index.index
        eachCallback()

  , (err, result) ->
    if err then done(err) else done()