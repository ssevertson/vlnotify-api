require('source-map-support').install()

before ->
  global.sinon = require('sinon')
  
  chai = require('chai')
  global.expect = chai.expect
  chai.use require('sinon-chai')
  
  global.async = require('async')

  app = require('../app/app')

  sinon.stub(app.storage, 'listBuckets').callsArgWithAsync 0, null, {
    Buckets: [
      {
        Bucket: 'vlnotify-cdn'
      }
    ]
  }
  sinon.stub(app.storage, 'createBucket').callsArgWithAsync 1, null, {
    Bucket: ''
  }
  sinon.stub(app.storage, 'putBucketCors').callsArgWithAsync 1, null, {}
  sinon.stub(app.storage, 'putObject').callsArgWithAsync 1, null, {}

  sinon.stub(app.cdn, 'listDistributions').callsArgWithAsync 1, null, {
    Items: []
  }
  sinon.stub(app.cdn, 'createDistribution').callsArgWithAsync 1, null, {
    Id: new Date().getTime().toString()
  }
  
  sinon.stub(app.cdn, 'createInvalidation').callsArgWithAsync 1, null, {}

  sinon.stub(app.index, 'createIndex').callsArgWithAsync 2, null, {}
  sinon.stub(app.index, 'createDocuments').callsArgWithAsync 2, null, {}

beforeEach ->
  require('resourceful').use('Memory')
