CPE = require '../../app/resources/cpe'

cpesDestroy = (cpes, callback) ->
  async.each cpes, (cpe, eachCallback) ->
    CPE.destroy cpe.id , (err, result) ->
      if err then eachCallback(err) else eachCallback()
  , (err) ->
    expect(err)
      .to.be.null
    callback()

describe 'CPE', ->

  it 'should validate CPE format', ->
    cpe = new CPE id: ''
    expect(cpe.validate().valid)
      .to.be.false
    cpe = new CPE id: 'asdf'
    expect(cpe.validate().valid)
      .to.be.false
    cpe = new CPE id: 'a'
    expect(cpe.validate().valid)
      .to.be.true
    cpe = new CPE id: 'a:vendor:product:version:update:edition:lang'
    expect(cpe.validate().valid)
      .to.be.true
    cpe = new CPE id: 'a:vendor:product:version:update:edition:lang:something'
    expect(cpe.validate().valid)
      .to.be.false
    cpe = new CPE id: 'a:<'
    expect(cpe.validate().valid)
      .to.be.false
    cpe = new CPE id: 'a:-'
    expect(cpe.validate().valid)
      .to.be.true

  it 'should create parent nodes as needed', (done) ->
    CPE.create {
      id: 'a:postgresql:postgresql:9.2'
      title_hint: 'PostgreSQL 9.2'
    }, (err, cpe) ->
      expect(err)
        .to.be.null
      expect(cpe)
        .to.have.property('id')
        .and.to.equal('a:postgresql:postgresql:9.2')
      expect(cpe)
        .to.have.property('title')
        .and.to.equal('9.2')
      CPE.all (err, cpes) ->
        expect(err)
          .to.be.null
        expect(cpes)
          .to.have.length(4)
        
        expectations = {
          'a': 'Application'
          'a:postgresql': 'PostgreSQL'
          'a:postgresql:postgresql': 'PostgreSQL'
          'a:postgresql:postgresql:9.2': '9.2'
        }
        
        for cpe in cpes
          expect(cpe.title)
            .to.equal(expectations[cpe.id])
        cpesDestroy cpes, done

  it 'should update titles as they become available', (done) ->
    CPE.create {
      id: 'a:postgresql:postgresql:9.2'
    }, (err, cpe) ->
      expect(err)
        .to.be.null
      expect(cpe)
        .to.have.property('id')
        .and.to.equal('a:postgresql:postgresql:9.2')
      cpe.update {
        title_hint: 'PostgreSQL 9.2'
      }, (err, updated) ->
        expect(err)
          .to.be.null
        expect(updated)
          .to.have.property('title')
          .and.to.equal('9.2')
        CPE.all (err, cpes) ->
          expectations = {
            'a': 'Application'
            'a:postgresql': 'PostgreSQL'
            'a:postgresql:postgresql': 'PostgreSQL'
            'a:postgresql:postgresql:9.2': '9.2'
          }
          for cpe in cpes
            expect(cpe.title)
              .to.equal(expectations[cpe.id])
          cpesDestroy cpes, done

  it 'should add more children as appropriate', (done) ->
    CPE.create {
      id: 'a:postgresql:postgresql:9.2'
    }, (err, cpe1) ->
      expect(err)
        .to.be.null
      expect(cpe1)
        .to.have.property('id')
        .and.to.equal('a:postgresql:postgresql:9.2')
      CPE.create {
        id: 'a:postgresql:postgresql:9.3'
      }, (err, cpe2) ->
        expect(err)
          .to.be.null
        expect(cpe2)
          .to.have.property('id')
          .and.to.equal('a:postgresql:postgresql:9.3')
        CPE.all (err, cpes) ->
          expect(cpes)
            .to.have.length(5)
          expectations = {
            'a': [
              { id: 'a:postgresql', title: 'Postgresql' }
            ]
            'a:postgresql': [
              { id: 'a:postgresql:postgresql', title: 'Postgresql' }
            ]
            'a:postgresql:postgresql': [
              { id: 'a:postgresql:postgresql:9.2', title: '9.2' }
              { id: 'a:postgresql:postgresql:9.3', title: '9.3' }
            ]
            'a:postgresql:postgresql:9.2': []
            'a:postgresql:postgresql:9.3': []
          }
          for cpe in cpes
            expect(cpe.children)
              .to.eql(expectations[cpe.id])
          cpesDestroy cpes, done

  it 'should maintain ancestor references', (done) ->
    CPE.create {
      id: 'a:postgresql:postgresql:9.2'
    }, (err, cpe1) ->
      expect(err)
        .to.be.null
      expect(cpe1)
        .to.have.property('id')
        .and.to.equal('a:postgresql:postgresql:9.2')
      expect(cpe1)
        .to.have.property('ancestors')
        .and.to.eql([
          { id: 'a', title: 'Application' }
          { id: 'a:postgresql', title: 'Postgresql' }
          { id: 'a:postgresql:postgresql', title: 'Postgresql' }
        ])
      CPE.create {
        id: 'a:postgresql:postgresql:9.3'
        title_hint: 'PostgreSQL 9.3'
      }, (err, cpe2) ->
        expect(err)
          .to.be.null
        expect(cpe2)
          .to.have.property('id')
          .and.to.equal('a:postgresql:postgresql:9.3')
        CPE.all (err, cpes) ->
          expect(cpes)
            .to.have.length(5)
          expectations = {
            'a': []
            'a:postgresql': [
              { id: 'a', title: 'Application' }
            ]
            'a:postgresql:postgresql': [
              { id: 'a', title: 'Application' }
              { id: 'a:postgresql', title: 'PostgreSQL' }
            ]
            #TODO: Only updates titles on ancestry, not descendants - note still "sql", not "SQL"
            'a:postgresql:postgresql:9.2': [
              { id: 'a', title: 'Application' }
              { id: 'a:postgresql', title: 'Postgresql' }
              { id: 'a:postgresql:postgresql', title: 'Postgresql' }
            ]
            'a:postgresql:postgresql:9.3': [
              { id: 'a', title: 'Application' }
              { id: 'a:postgresql', title: 'PostgreSQL' }
              { id: 'a:postgresql:postgresql', title: 'PostgreSQL' }
            ]
          }
          for cpe in cpes
            expect(cpe.ancestors)
              .to.eql(expectations[cpe.id])
          cpesDestroy cpes, done

  xit 'should index on create', (done) ->
    app = require('../../app/app')
    
    app.index.createDocuments.reset()
    
    CPE.create {
      id: 'a:postgresql:postgresql:9.2'
      title_hint: 'PostgreSQL 9.2'
    }, (err, result) ->
      expect(err)
        .to.be.null
      expect(result)
        .to.be.not.null
      expect(app.index.createDocuments)
        .to.be.called
        
      indexDocMatch = {
        docid: 'cpe/a:postgresql:postgresql:9.2'
        fields:
          text: 'PostgreSQL PostgreSQL 9.2'
        categories:
          type: 'cpe'
          part: 'a'
          vendor: 'postgresql'
          product: 'postgresql'
          version: '9.2'
      }
      expect(app.index.createDocuments)
        .to.be.calledWith \
          sinon.match.string,
          sinon.match(indexDocMatch),
          sinon.match.func
      CPE.all (err, cpes) ->
        cpesDestroy cpes, done
          