resourceful = require 'resourceful'
restful = require 'restful'
util = require 'utile'
helpers = require '../util/resource_helpers'
inflect = require 'inflect'
CPEURI = require '../util/cpe_uri'
CPETitle = require '../util/cpe_title'


CPE = module.exports = resourceful.define 'cpe', ->
  @restful = true
  @key = 'id'

  util.mixin @schema, {
    properties:
      id:
        type: 'string'
        required: true
        pattern: /^[hoa](?::[\w-.~%]+){0,6}$/
      title:
        type: 'string'
      ancestors:
        type: 'array'
        items:
          type: 'object'
          additionalProperties: false
          properties:
            id:
              type: 'string'
              required: true
              pattern: /^[hoa](?::[\w-.~%]+){0,6}$/
            title:
              type: 'string'
      children:
        type: 'array'
        items:
          type: 'object'
          additionalProperties: false
          properties:
            id:
              type: 'string'
              required: true
              pattern: /^[hoa](?::[\w-.~%]+){0,6}$/
            title:
              type: 'string'
    additionalProperties:
      properties:
        title_hint:
          type: 'string'
        title_parsed:
          type: 'object'
          additionalProperties: false
          properties:
            part:
              type: 'string'
            vendor:
              type: 'string'
            product:
              type: 'string'
            version:
              type: 'string'
            update:
              type: 'string'
            edition:
              type: 'string'
            lang:
              type: 'string'
            sw_edition:
              type: 'string'
            target_sw:
              type: 'string'
            target_hw:
              type: 'string'
            other:
              type: 'string'
  }

  # Dynamic default values
  Object.defineProperty @schema.properties.children, 'default',
    get: -> []
  Object.defineProperty @schema.properties.ancestors, 'default',
    get: -> []

  @before 'create', helpers.authorize('admin')
  @before 'update', helpers.authorize('admin')
  @before 'destroy', helpers.authorize('admin')

  createParentsAndFixTitles = (cpe, callback) ->
    cpeId = helpers.unprefixResourceId cpe
    wfn = CPEURI.unbind cpeId

    # Rebind to ensure consistent formatting/escaping
    cpeId = CPEURI.bind wfn

    titles = if cpe.title_parsed and Object.keys(cpe.title_parsed).length
      cpe.title_parsed
    else
      CPETitle.generateTitles wfn, cpe.title_hint
    delete cpe.properties.title_hint if cpe.properties
    delete cpe.properties.title_parsed if cpe.properties

    ancestors = CPETitle.generateTitlesByAncestry wfn, titles
    cpe.title = ancestors.pop().title
    cpe.ancestors = ancestors

    parentId = ancestors[ancestors.length - 1].id if ancestors.length > 0
    if parentId
      CPE.get parentId, (err, parentCpe) ->
        if err
          if err.status is 404
            console.log.info "Creating parent #{parentId}"
            timer = console.log.startTimer()
            CPE.create  {
              id: parentId,
              title_parsed: titles
              children: [
                {
                  id: cpeId
                  title: cpe.title
                }
              ]
              ancestors: ancestors
            }, (err, parentCpe) ->
              timer.done "Created parent #{parentId}"
              if err then callback(err) else callback()
          else
            callback(err)
        else
          updates = {
            title_parsed: titles
          }
          if not parentCpe.children?.some?( (child) -> cpeId is child.id )
            updates.children = parentCpe.children || []
            updates.children.push {
              id: cpeId
              title: cpe.title
            }
          console.log.info "Updating parent #{parentId}"
          timer = console.log.startTimer()
          parentCpe.update updates, (err, parentCpe) ->
            timer.done "Updated parent  #{parentId}"
            if err then callback(err) else callback()
    else
      callback()

  @before 'create', createParentsAndFixTitles
  @before 'update', createParentsAndFixTitles

  @after 'create', helpers.upload('data')
  @after 'update', helpers.upload('data')

  @after 'create', helpers.index('data')
  @after 'update', helpers.index('data')

  @after 'update', helpers.invalidate('data')
  
  # Can't invalidate or unindex after destroy, as the after method does not receive the resource
  

  # Define stored filters (avoid temporary views)
  @filter 'all', {}

CPE.prototype.buildIndexDocument = ->
  allTitles = (ancestor.title for ancestor in @ancestors when ancestor?.id?.length > 1)
  allTitles.push @title

  doc = {
    docid: helpers.prefixResourceId @
    fields:
      text: allTitles.join(' ')
      timestamp: new Date().getTime() * 0.001
    categories:
      type: @resource.toLowerCase()
  }
  util.mixin doc.categories, CPEURI.unbind(@id)
  return doc
  