util = require 'utile'
inflect = require 'inflect'
cpe_uri = require 'cpe-uri'
RegExp.quote = require 'regexp-quote'

CPETitle = module.exports

cleanSpecialChars = (string) ->
  if string is undefined then return ''
  return string.replace(/[_\-:]+/g, ' ')
    .replace(/([0-9])([a-zA-Z])/i, '$1 $2')
    .trim()
    
prepareSegments = (wfn) ->
  segments = []
  lastSegment = null

  cpe_uri.forEach wfn, (componentName, value) ->
    clean = cleanSpecialChars(value)
    
    # If the first element of a multi-segment segment matches the previous segment, exclude it
    split = clean.split(/\s+/)
    if lastSegment and split.length > 1 and lastSegment.original is split[0]
      split.shift()
    join = split.join('')
    
    segments.push lastSegment = {
      original: value
      split: split
      join: join
      component: componentName
    }
  return segments

getFirstSegmentTitle = (value) ->
  return switch value
    when 'a' then 'Application'
    when 'h' then 'Hardware'
    when 'o' then 'Operating System'
    else throw new Error('Unknown CPE prefix: ' + value)

segmentsToResults = (segments) ->
  return new ->
    @[segment.component] = segment.title for segment in segments when segment.title
    return @

prepareTerms = (title) ->
  terms = for term in title.trim().split(/\s+/)
    clean = cleanSpecialChars(term)
    split = clean.split(/\s+/)
    join = split.join('')
    {
      original: term
      split: split
      join: join
    }
  return terms

append = (current, append) ->
  return if current and current isnt append then current + ' ' + append else append

matchWithNGrams = (terms, segment) ->
  used = false
  lower = false
  expression = new RegExp('^' + RegExp.quote(segment.join) + '$', 'i')
  for term, start in terms
    for end in [start..terms.length]
      subset = terms[start...end]
      ngram = (term.join for term in subset).join('')
      result = expression.exec(ngram)
      if result
        segment.title = (term.original for term in subset).join(' ')
        segment.lastTerm = end - 1
        used = subset.some (term) -> term.used
        lower = segment.title is segment.title.toLocaleLowerCase()
        for term in subset
          term.used = true
        return true if not used and not lower
          
  return if segment.title then true else false

matchWithJoinedSegments = (terms, segment) ->
  expression = new RegExp('^' + RegExp.quote(segment.join), 'i')
  for term, termNum in terms
    found = false
    for chunk in term.split
      result = expression.exec(chunk)
      if result
        segment.title = append segment.title, chunk
        segment.lastTerm = Math.max(segment.lastTerm || 0, termNum)
        term.used = true
        return true
  return false
  
matchWithSplitSegments = (terms, segment) ->
  return false if segment.split.length is 1

  for piece in segment.split
    found = false
    expression = new RegExp('^' + RegExp.quote(piece), 'i')
    for term, termNum in terms
      for chunk in term.split
        result = expression.exec(chunk)
        if result
          segment.title = append segment.title, chunk
          segment.lastTerm = Math.max(segment.lastTerm || 0, termNum)
          term.used = true
          found = true
          break
      break if found
    if not found
      segment.title = append segment.title, inflect.titleize(piece)
  return true

appendUnusedTerms = (terms, segments) ->
  for segment in segments.slice().reverse()
    lastTerm = (segment.lastTerm || 0)
    if lastTerm < terms.length and not segment.skip
      for term, termNum in terms when termNum > lastTerm
        break if term.used
        segment.title = append segment.title, term.original
        term.used = true

titleCleanup = (segments) ->
  for segment, i in segments
    if segment.title
      segment.title = switch segment.component
        when 'vendor' then segment.title.replace(/[:]/, '')
        when 'version' then segment.title.replace(/([0-9x])\s+(\d)/g, '$1-$2')
        else segment.title


CPETitle.generateTitles = (wfn, title) ->
  wfn = cpe_uri.unbind wfn if wfn.part is undefined
  segments = prepareSegments(wfn)
  
  first = segments.shift()
  first.title = getFirstSegmentTitle(first.original)
  
  if not title
    segment.title = inflect.titleize(segment.original) for segment in segments
    segments.unshift(first)
    return segmentsToResults(segments)

  terms = prepareTerms(title)

  lastSegment = null
  for segment in segments
    continue if not segment.join

    matchWithNGrams(terms, segment) \
    or matchWithJoinedSegments(terms, segment) \
    or matchWithSplitSegments(terms, segment)

    # Prevent version segment from consuming additional unused terms if trailing data is present
    # Can often include words that actually belong to the sw_edition or target_sw, e.g.
    # "195.22 for VMWare ESX" - the "for VMWare" segment isn't part of the version data
    if segment.component is 'version' and segment.title \
    and (wfn.lang or wfn.sw_edition or wfn.target_sw or wfn.target_hw or wfn.other)
      segment.skip = true

    # If we didn't match a single part of the segment to the title, prevent the previous segment
    # from consuming additional unused terms
    if lastSegment and segment.lastTerm is undefined
      segment.lastTerm = lastSegment.lastTerm
      lastSegment.skip = true
    lastSegment = segment

  appendUnusedTerms(terms, segments)

  segments.unshift(first)
  titleCleanup(segments)
        
  return segmentsToResults(segments)

CPETitle.generateTitlesByAncestry = (wfn, titles) ->
  wfn = cpe_uri.unbind wfn if wfn.part is undefined
  titles = CPETitle.generateTitles(wfn, titles) if titles.part is undefined
  
  result = []
  wfnTemp = {}
  cpe_uri.forEach wfn, (componentName, value) ->
    wfnTemp[componentName] = value
    result.push {
      id: cpe_uri.bind wfnTemp
      title: titles[componentName]
    }
  return result
