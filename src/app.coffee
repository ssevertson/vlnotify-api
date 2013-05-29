require('source-map-support').install()
path = require 'path'
util = require 'utile'
loggly = require 'winston-loggly'
flatiron = require 'flatiron'
resourceful = require 'resourceful'
restful = require 'restful'
connect = require 'connect'
cors = require 'connect-xcors'
jsonp = require 'connect-jsonp'
domain = require 'domain'
aws = require 'aws-sdk'
dustRenderStrings = require 'dust-render-strings'

app = module.exports = flatiron.app
app.root = path.dirname __dirname

app.config
  .argv()
  .env('_')
  .file(path.join app.root, 'config/config.json')

# Support dust.js templates in config strings to reduce redundant values
app.config.stores.literal.store = dustRenderStrings(app.config.get())


# flatiron/broadway currently depend on Winston 0.6.2
# We want 0.7.x for string interpolation
app.use require './util/log.js'

# Replace console.log with winston.info by default; augment with all other Winston methods
console.log = app.log.info
for key, val of app.log
  console.log[key] = val
  
app.use flatiron.plugins.http,
  before: [
    connect.compress()
    cors app.config.get('cors')
    jsonp()
    (req, res, next) ->
      # Use process.domain as thread-local storage.
      # Restful/Resourceful don't expose req/res, which are needed for per-resource authorization
      process.domain = domain.create()
      process.domain.req = req
      process.domain.res = res
      next()
  ]

# Configure Resourceful here, so filters get configured correctly
if process.env['NODE_ENV'] is 'production'
  resourceful.use \
    app.config.get('resourceful:production:engine'),
    app.config.get('resourceful:production')
else
  resourceful.use \
    app.config.get('resourceful:default:engine'),
    app.config.get('resourceful:default')
app.use flatiron.plugins.resourceful

app.router.param(':vlnid', /([._a-zA-Z0-9-:%]+)/)
app.use restful,
  param: ':vlnid'
  explore: true
  respond: (req, res, status, key, value) ->
    if arguments.length is 5
      result = {}
      result[key] = value
    else
      result = key

    if result.statusCode
      status = result.statusCode

    res.writeHead status, { 'Content-Type': 'application/json' }
    
    json = if result then JSON.stringify(result) else ''
    app.log.info 'API Result: %d bytes', json.length
    res.end json

app.use require('./init/cdn')
app.use require('./init/index')

unless Object.keys(app.router.routes).length
  app.log.error 'No routes set up!'
  process.exit 1