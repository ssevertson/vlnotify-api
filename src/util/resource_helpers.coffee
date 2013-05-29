require 'date-utils'

Helpers = module.exports

Helpers.authorize = (roles...) ->

  HEADER = 'x-api-key'

  return (resource, callback) ->
    if !process.domain
      # Assume resource is being used directly (as support in a test); no authorization required
      callback()
      return
      
    
    {req, res, role} = process.domain
    if role and role in roles
      # We've previously authenticated this request'
      callback()
      return
    
    apiKey = req.headers[HEADER]
    if !apiKey
      callback
        statusCode: 401
        error: "Missing required header #{HEADER}"
      return
    
    isUserResource = resource.resource is 'User' or resource.id.indexOf('user/') is 0
    isApiKeyUser = resource.id is "user/#{apiKey}"
    
    if isUserResource and isApiKeyUser
      # We're authorizing a User to access their own data
      # Short circuit to save time, and prevent stack overflow from circular dependencies
      callback()
      return
    
    User = require '../resources/user'
    console.log.info('Retrieving User: %s', apiKey.substring(0, 8) + '...')
    timer = console.log.startTimer() if console.log.startTimer
    User.get apiKey, (err, user) ->
      timer.done('Retrieved User: ' + apiKey.substring(0, 8) + '...')
      if user and user.role
      
        # Cache the user's role on the domain for the remainder of the request
        # TODO: Consider caching user roles for longer (fixed size, LRU eviction?)
        process.domain.role = user.role
        
        if isUserResource && user.role is 'user'
          if isApiKeyUser
            callback()
            return
        else if user.role in roles
          callback()
          return
      
      # Default to unauthorized
      callback
        statusCode: 401
        error: "Unauthorized"


Helpers.invalidate = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    distributionId = app.cdn.distributions[key]

    id = Helpers.prefixResourceId resource

    console.log.info('Invalidating ' + id + ' in storage')
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
      timer.done('Invalidated ' + id + ' in storage')
      callback(err)


Helpers.upload = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    bucketName = app.storage.buckets[key]
    id = Helpers.prefixResourceId resource
    
    console.log.info('Uploading ' + id + ' to bucket ' + key)
    timer = app.log.startTimer()
    app.storage.putObject {
      ACL: 'public-read'
      Body: JSON.stringify(resource)
      Bucket: bucketName
      Key: id + '.json'
      ContentType: 'application/json'
      CacheControl: 'public'
      Expires: new Date().addHours(1)
    }, (err, data) ->
      timer.done('Upload ' + id + ' to bucket ' + key)
      callback(err)


Helpers.index = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    indexName = app.index.indexes[key]
    id = Helpers.prefixResourceId(resource)

    console.log.info('Indexing ' + id)
    timer = app.log.startTimer()
    app.index.createDocuments \
      indexName, \
      resource.buildIndexDocument(), \
      (err, data) ->
      timer.done('Indexed ' + id)
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