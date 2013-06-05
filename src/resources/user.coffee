resourceful = require 'resourceful'
restful = require 'restful'
util = require 'utile'
uuid = require 'node-uuid'
helpers = require '../util/resource_helpers'

User = module.exports = resourceful.define 'user', ->
  @restful = true
  @key = 'id'

  util.mixin @schema, {
    additionalProperties: false
    properties:
      id:
        type: 'string'
        required: true
        minLength: 36
        maxLength: 36
      role:
        type: 'string'
        required: true
        enum: ['user', 'admin']
      date_created:
        type: 'string'
        required: true
        format: 'date-time'
      date_updated:
        type: 'string'
        required: true
        format: 'date-time'
      subscription:
        type: 'array'
        items:
          type: 'string'
          format: 'uri'
        uniqueItems: true
    }

  # Dynamic default values
  Object.defineProperty @schema.properties.id, 'default',
    get: ->
      uuid.v4 {rng: uuid.nodeRNG}
  Object.defineProperty @schema.properties.date_created, 'default',
    get: ->
      new Date().toISOString()
  Object.defineProperty @schema.properties.date_updated, 'default',
    get: ->
      new Date().toISOString()

  @before 'create', helpers.authorize('user', 'admin')
  @before 'update', helpers.authorize('user', 'admin')
  @before 'filter', helpers.authorize('user', 'admin')
  @before 'find', helpers.authorize('user', 'admin')
  @before 'get', helpers.authorize('user', 'admin')
  @before 'destroy', helpers.authorize('user', 'admin')
  
  # Define stored filters (avoid temporary views)
  @filter 'all', {}
  