util = require 'utile'

CPEURI = module.exports

class Component
  constructor: (@id, @name) ->

class Components
  constructor: (names) ->
    @ascending = (new Component(id, name) for name, id in names)
    @descending = @ascending.slice().reverse()
    @[component.name] = component for component in @ascending

components = new Components [
  'part'
  'vendor'
  'product'
  'version'
  'update'
  'edition'
  'lang'
  'sw_edition'
  'target_sw'
  'target_hw'
  'other'
]

packed = new Components [
  'edition'
  'sw_edition'
  'target_sw'
  'target_hw'
  'other'
]

CPEURI.unbind = (cpeUri) ->
  cpeUri = cpeUri.replace(/^cpe:?\//, '')
  values = (decodeURIComponent(value) for value in cpeUri.split(/:/))
  wfn = {}
  for value, id in values[components.part.id..components.lang.id]
    component = components.ascending[id]
    if component is components.edition and value and value.charAt(0) is '~'
      for value, id in value[1..].split(/~/)
        wfn[packed.ascending[id].name] = value
    else
      wfn[component.name] = value
  return wfn

CPEURI.bind = (wfn) ->
  cpeUri = []
  for component in components.ascending[components.part.id..components.lang.id]
    value = wfn[component.name] || ''
    if component is components.edition \
    and packed.ascending[packed.sw_edition.id..].some((packed) -> wfn[packed.name])
      value = '~' + packed.ascending.map((packed) -> wfn[packed.name]).join('~')
    cpeUri.push encodeURIComponent(value)
  return cpeUri.join(':').replace(/:+$/, '')

CPEURI.getMostSpecificComponentName = (wfn) ->
  wfn = CPEURI.unbind wfn if wfn.part is undefined
  for component in components.descending
    if wfn[component.name]
      return component.name
  return null

CPEURI.makeLessSpecific = (wfn) ->
  wfn = CPEURI.unbind wfn if wfn.part is undefined
  wfn = util.clone(wfn)
  componentName = CPEURI.getMostSpecificComponentName(wfn)
  delete wfn[componentName] if componentName
  return wfn

CPEURI.bindLessSpecific = (wfn) ->
  wfn = CPEURI.unbind wfn if wfn.part is undefined
  wfn = CPEURI.makeLessSpecific wfn
  return CPEURI.bind wfn

CPEURI.forEach = (wfn, callback) ->
  wfn = CPEURI.unbind wfn if wfn.part is undefined
  for component in components.ascending
    value = wfn[component.name]
    callback(component.name, value) if value
  return undefined

CPEURI.generateUniqueComponentLists = (wfns) ->
  wfns = [wfns] unless Array.isArray(wfns)
  result = {}
  for wfn in wfns
    wfn = CPEURI.unbind wfn if wfn.part is undefined
    CPEURI.forEach wfn, (component, value) ->
      current = result[component]
      if not current
        result[component] = current = {}
      current[value] = true

  # Convert nested objects to arrays of keys
  return new ->
    @[key] = Object.keys(value) for key, value of result
    return @

CPEURI.generateUniqueAncestors = (wfns) ->
  wfns = [wfns] unless Array.isArray(wfns)
  ancestors = {}
  for wfn in wfns
    wfn = CPEURI.unbind wfn if wfn.part is undefined
    wfnTemp = {}
    CPEURI.forEach wfn, (componentName, value) ->
      wfnTemp[componentName] = value
      ancestors[CPEURI.bind(wfnTemp)] = true

  return Object.keys(ancestors)