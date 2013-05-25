resourceful = require 'resourceful'
restful = require 'restful'
util = require 'utile'
helpers = require '../util/resource_helpers'

Source = module.exports = resourceful.define 'source', ->
  @restful = true
  @key = 'id'
  
  util.mixin @schema, {
    additionalProperties: false
    properties:
      id:
        type: 'string'
        required: true
      url:
        type: 'string'
        required: true
        format: 'uri'
      date_created:
        type: 'string'
        required: true
        format: 'date-time'
      date_updated:
        type: 'string'
        required: true
        format: 'date-time'
  }

  # Dynamic default values
  Object.defineProperty @schema.properties.date_created, 'default',
    get: ->
      new Date().toISOString()
  Object.defineProperty @schema.properties.date_updated, 'default',
    get: ->
      new Date().toISOString()

  @before 'create', helpers.authorize('admin')
  @before 'update', helpers.authorize('admin')
  @before 'destroy', helpers.authorize('admin')
  
  # Define stored filters (avoid temporary views)
  @filter 'all', {}
