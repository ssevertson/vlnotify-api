app = require '../app/app'
request = require 'request'
User = require '../app/resources/user'
Source = require '../app/resources/source'
PORT = Math.floor(Math.random() * 65535 - 1024) + 1024

userCreate = (role, callback) ->
  User.create {
    role: role
  }, (err, user) ->
    expect(err)
      .to.be.null
    expect(user)
      .to.have.property('id')
    expect(user)
      .to.have.property('role')
      .and.to.equal(role)
    callback user

userDestroy = (userId, callback) ->
  User.destroy userId, (err, result) ->
    expect(err)
      .to.be.null
    callback()

sourceDestroy = (sourceId, callback) ->
  Source.destroy sourceId, (err, result) ->
    expect(err)
      .to.be.null
    callback()

describe 'Authentication', ->
  self = this
  uri = 'http://localhost:' + PORT
  before (done) ->
    app.init (err) ->
      if err
        app.log.error 'Error during initialization: %j', err
        throw err
      app.listen PORT, ->
        done()

  it 'should allow anonymous read-only access to sources', (done) ->
    request.get uri + '/source', (err, resp) ->
      expect(err)
        .to.be.null
      expect(resp)
        .to.have.property('statusCode')
        .and.to.equal(200)
      done()

  it 'should not allow anonymous writeable access to sources', (done) ->
    request.post {
      url: uri + '/source'
      json:
        id: 'foo'
        url: 'http://example.com'
        last_update: '2013-01-01T00:00:00.000Z'
    }, (err, resp) ->
      expect(err)
        .to.be.null
      expect(resp)
        .to.have.property('statusCode')
        .and.to.equal(401)
      done()

  it 'should allow authenticated with appropriate role writeable access to sources', (done) ->
    userCreate 'admin', (admin) ->
      request.post {
        url: uri + '/source'
        json:
          id: 'foo'
          url: 'http://example.com'
          last_update: '2013-01-01T00:00:00.000Z'
        headers:
          'X-API-Key': admin.id
      }, (err, resp) ->
        expect(err)
          .to.be.null
        expect(resp)
          .to.have.property('statusCode')
          .and.to.equal(201)
        
        sourceDestroy 'foo', ->
          userDestroy admin.id, ->
            done()

  it 'should not allow authenticated with inappropriate role writeable access to sources', (done) ->
    userCreate 'user', (user) ->
      request.post {
        url: uri + '/source'
        json:
          id: 'foo'
          url: 'http://example.com'
          last_update: '2013-01-01T00:00:00.000Z'
        headers:
          'X-API-Key': user.id
      }, (err, resp) ->
        expect(err)
          .to.be.null
        expect(resp)
          .to.have.property('statusCode')
          .and.to.equal(401)
        
        userDestroy user.id, ->
          done()

  it 'should allow authenticated self access to user', (done) ->
    userCreate 'user', (user) ->
      request.get {
        url: uri + '/user/' + user.id
        headers:
          'X-API-Key': user.id
      }, (err, resp) ->
        expect(err)
          .to.be.null
        expect(resp)
          .to.have.property('statusCode')
          .and.to.equal(200)
        
        userDestroy user.id, ->
          done()

  it 'should allow authenticated admin access to any user', (done) ->
    userCreate 'user', (user) ->
      userCreate 'admin', (admin) ->
        request.get {
          url: uri + '/user/' + user.id
          headers:
            'X-API-Key': admin.id
        }, (err, resp) ->
          expect(err)
            .to.be.null
          expect(resp)
            .to.have.property('statusCode')
            .and.to.equal(200)
        
          userDestroy user.id, ->
            userDestroy admin.id, ->
              done()

  it 'should not allow authenticated with non-self user any access to user', (done) ->
    userCreate 'user', (user1) ->
      userCreate 'user', (user2) ->
      
        request.get {
          url: uri + '/user/' + user1.id
          headers:
            'X-API-Key': user2.id
        }, (err, resp) ->
          expect(err)
            .to.be.null
          expect(resp)
            .to.have.property('statusCode')
            .and.to.equal(404)
        
          userDestroy user1.id, ->
            userDestroy user2.id, ->
              done()
