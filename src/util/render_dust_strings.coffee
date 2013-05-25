dust = require 'dustjs-linkedin'
type = require 'tea-type'

renderDustStrings = module.exports = (obj, context) ->
  context = context || obj
  for key, value of obj
    switch type(value)
      when 'string'
        if value.indexOf('{') isnt -1
          compiled = dust.compile value, 'temp'
          dust.loadSource compiled
          # DustJS is only asynchronous if loading partials, or using helpers that call chunk.map
          # We're not loading helpers, but if the config references partials, this will not work
          dust.render 'temp', context, (err, result) ->
            delete dust.cache['temp']
            obj[key] = result
      when 'array'
        for val, index in value
          value[index] = renderDustStrings val, context
      when 'object'
        obj[key] = renderDustStrings value, context
  return obj
