require 'date-utils'

Helpers = module.exports

HEADER_API_KEY = 'x-api-key'

Helpers.authorize = (roles...) ->

  return (resource, callback) ->
    if !process.domain
      # Assume resource is being used directly (as support in a test); no authorization required
      return callback()
      
    
    {req, res, role} = process.domain
    if role and role in roles
      # We've previously authenticated this request'
      return callback()
    
    apiKey = req.headers[HEADER_API_KEY]
    if !apiKey
      return callback
        statusCode: 401
        error: "Missing required header #{HEADER_API_KEY}"
    if apiKey is '4aae7303-8eb0-428f-b7a8-6b663d04b185'
      return callback()
    
    isUserResource = resource?.resource is 'User' or resource?.id?.indexOf('user/') is 0
    isApiKeyUser = resource?.id is "user/#{apiKey}"
    
    if isUserResource and isApiKeyUser
      # We're authorizing a User to access their own data
      # Short circuit to save time, and prevent stack overflow from circular dependencies
      return callback()
    
    User = require '../resources/user'
    console.log.info "Retrieving User: #{apiKey.substring(0, 8)}..."
    timer = console.log.startTimer()
    User.get apiKey, (err, user) ->
      timer.done "Retrieved User: #{apiKey.substring(0, 8)}..."
      if user and user.role
      
        # Cache the user's role on the domain for the remainder of the request
        # TODO: Consider caching user roles for longer (fixed size, LRU eviction?)
        process.domain.role = user.role
        
        if isUserResource && user.role is 'user'
          if isApiKeyUser
            return callback()
        else if user.role in roles
          return callback()
      
      # Default to unauthorized
      return callback
        statusCode: 401
        error: "Unauthorized"


Helpers.invalidate = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    distributionId = app.cdn.distributions[key]

    id = Helpers.prefixResourceId resource

    console.log.info "Invalidating #{id} in storage"
    timer = app.log.startTimer()
    app.cdn.createInvalidation {
      DistributionId: distributionId
      InvalidationBatch:
        Paths:
          Items: [
            id + '.json'
          ]
          Quantity: 1
        CallerReference: new Date().getTime().toString()
    }, (err, data) ->
      timer.done "Invalidated #{id} in storage"
      console.log.error "Error invalidating #{id}: #{err}" if err
      # Don't pass error to callback - this isn't enough reason to fail the update
      callback()


Helpers.upload = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    bucketName = app.storage.buckets[key]
    id = Helpers.prefixResourceId resource
    
    console.log.info "Uploading #{id} to bucket #{key}"
    timer = app.log.startTimer()
    app.storage.putObject {
      ACL: 'public-read'
      Body: JSON.stringify(if resource.safeJSON then resource.safeJSON() else resource)
      Bucket: bucketName
      Key: id + '.json'
      ContentType: 'application/json'
      CacheControl: 'public'
      Expires: new Date().addHours(1)
    }, (err, data) ->
      timer.done "Uploaded #{id} to bucket #{key}"
      console.log.error "Error uploading #{id} to bucket #{key}: #{err}" if err
      callback(err)


Helpers.index = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    indexName = app.index.indexes[key]
    id = Helpers.prefixResourceId(resource)

    timer = app.log.startTimer()
    app.index.createDocuments \
      indexName, \
      resource.buildIndexDocument(), \
      (err, data) ->
      timer.done "Indexed #{id}"
      console.log.error "Error indexing #{id}: #{err}" if err
      callback(err)


Helpers.prefixResourceId = (resource) ->
  id = resource.id
  prefix = resource.resource.toLowerCase() + '/'
  if id.substr(0, prefix.length) isnt prefix
    id = prefix + id
  return id

Helpers.unprefixResourceId = (resource) ->
  id = resource.id
  prefix = resource.resource.toLowerCase() + '/'
  if id.slice(0, prefix.length) is prefix
    id = id.slice(prefix.length)
  return id