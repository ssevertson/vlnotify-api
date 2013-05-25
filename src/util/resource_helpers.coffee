require 'date-utils'

Helpers = module.exports

Helpers.authorize = (roles...) ->

  HEADER = 'x-api-key'

  return (resource, callback) ->
    if !process.domain
      # Assume resource is being used directly (as support in a test); no authorization required
      callback()
      return
    
    {req, res} = process.domain
    apiKey = req.headers[HEADER]
    if !apiKey
      callback
        statusCode: 401
        error: "Missing required header #{HEADER}"
      return
    
    isUserResource = resource.resource is 'User'
    isApiKeyUser = resource.id is "user/#{apiKey}"
    
    if isUserResource and isApiKeyUser
      # We're authorizing a User to access their own data
      # Short circuit to save time, and prevent stack overflow from circular dependencies
      callback()
      return
    
    User = require '../resources/user'
    User.get apiKey, (err, user) ->
      if user and user.role
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
      if err then callback(err) else callback()

Helpers.upload = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    bucketName = app.storage.buckets[key]

    id = Helpers.prefixResourceId resource
    
    app.storage.putObject {
      ACL: 'public-read'
      Body: JSON.stringify(resource)
      Bucket: bucketName
      Key: id + '.json'
      ContentType: 'application/json'
      CacheControl: 'public'
      Expires: new Date().addHours(1)
    }, (err, data) ->
      if err then callback(err) else callback()

Helpers.index = (key) ->
  app = require '../../app/app'
  return (err, resource, callback) ->
    indexName = app.index.indexes[key]

    app.index.createDocuments \
      indexName, \
      resource.buildIndexDocument(), \
      (err, data) ->
      if err then callback(err) else callback()



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