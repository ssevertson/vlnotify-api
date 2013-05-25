User = require '../../app/resources/user'

describe 'User', ->
  it 'should have a default date_created', ->
    user = new User()
    expect(user)
      .to.have.property('date_created')
      .and.to.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z$/)

  it 'shouldn\'t override a supplied date_created', ->
    user = new User {date_created: '2013-01-01T00:00:00.000Z'}
    expect(user)
      .to.have.property('date_created')
      .and.to.equal('2013-01-01T00:00:00.000Z')
      
  it 'should have a default id', ->
    user = new User()
    expect(user)
      .to.have.property('id')
      .and.to.match(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)

  it 'shouldn\'t override a supplied id', ->
    user = new User {id: '109156be-c4fb-41ea-b1b4-efe1671c5836'}
    expect(user)
      .to.have.property('id')
      .and.to.equal('109156be-c4fb-41ea-b1b4-efe1671c5836')
