###

  SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

XMLHttpRequest = XMLHttpRequest or require('xmlhttprequest').XMLHttpRequest
{abs, pow} = Math

isArray = Array.isArray or (obj) ->
  toString.call(obj) == '[object Array]'

urlencode = (params) ->
  params = for k, v of params
    "#{k}=#{encodeURIComponent(v.toString())}"
  params.join('&')

xhrGET = (options) ->
  {url, params, callback, rawResponse} = options
  url = "#{url}?#{urlencode(params)}"

  request = new XMLHttpRequest()
  request.open('GET', url, true)
  request.addEventListener 'readystatechange', ->
    return unless request.readyState == 4
    if request.status == 200
      data = if rawResponse
        request.responseText
      else
        JSON.parse(request.responseText)

      callback(undefined, data)
    else
      callback(request, undefined)

  request.send()

extend = (obj, objs...) ->
  for o in objs
    for k, v of o
      obj[k] = v
  obj

idCounter = 0

uniqueId = (prefix) ->
  id = ++idCounter + ''
  if prefix then prefix + id else id

EventEmitter =

  on: (name, callback) ->
    if not this.hasOwnProperty("_handlers")
      this._handlers = {}
    handlers = this._handlers;
    if not handlers.hasOwnProperty(name)
      handlers[name] = []
    list = handlers[name]
    list.push(callback)

  once: (name, callback) ->
    remove = =>
      this.off(name, callback)
      this.off(name, remove)
    this.on(name, callback)
    this.on(name, remove)

  emit: (name, args...) ->
    return unless this.hasOwnProperty("_handlers")
    handlers = this._handlers
    return unless handlers.hasOwnProperty(name)
    list = handlers[name]
    for l in list
      continue unless l
      l.apply(this, args)

  off: (name, callback) ->
    return unless this.hasOwnProperty("_handlers")
    handlers = this._handlers
    return unless handlers.hasOwnProperty(name)
    list = handlers[name]
    index = list.indexOf(callback)
    return if index < 0
    list[index] = false
    if index == list.length - 1
      while index >= 0 and not list[index]
        list.length--
        index--

# Alternative APIs
EventEmitter.addListener = EventEmitter.on
EventEmitter.addEventListener = EventEmitter.on

EventEmitter.removeListener = EventEmitter.off
EventEmitter.removeEventListener = EventEmitter.off

EventEmitter.trigger = EventEmitter.emit

class Module

  @include: (mixins...) ->
    for mixin in mixins
      extend(this.prototype, mixin)

ResolverShortcuts = 

  searchDebug: (query) ->
    qid = uniqueId('query')
    this.once 'results', (results) ->
      console.log results.results
    this.search(qid, query)
    return

  resolveDebug: (track, artist, album) ->
    qid = uniqueId('resolve')
    this.once 'results', (results) ->
      console.log results.results
    this.resolve(qid, track, artist, album)
    return

class BaseResolver extends Module
  @include EventEmitter, ResolverShortcuts

  name: undefined

  options:
    includeRemixes: true
    includeCovers: true
    includeLive: true

  constructor: (options = {}) ->
    this.options = extend({}, this.options, options)

  request: (opts) ->
    xhrGET(opts)

  search: (qid, query) ->
    throw new Error('not implemented')

  resolve: (qid, track, artist, album) ->
    query = (artist or '') + (track or '')
    this.search(qid, query.trim())

  results: (qid, results) ->
    if results?.length? and results.length > 0
      this.emit('results', {qid: qid, results: results})

class ResolverSet extends Module
  @include EventEmitter, ResolverShortcuts

  constructor: (resolvers...) ->
    this.resolvers = if isArray(resolvers[0]) then resolvers[0] else resolvers

    for resolver in this.resolvers
      resolver.on 'results', (results) =>
        this.emit('results', results)

  search: (qid, query) ->
    for resolver in this.resolvers
      resolver.search(qid, query)

  resolve: (qid, track, artist, album) ->
    for resolver in this.resolvers
      resolver.resolve(qid, track, artist, album)

tokenNormalizeRe = /[^a-z0-9 ]+/g
spaceNormalizeRe = /[ \t\n]+/g

ngrams = (toks, rank = 2) ->
  buf = []
  for tok in toks
    buf.push(tok)
    continue unless buf.length == rank
    ng = buf.join(' ')
    buf.shift()
    ng

tokenize = (str, ngram = 1) ->
  str
    .toLowerCase()
    .replace(tokenNormalizeRe, ' ')
    .replace(spaceNormalizeRe, ' ')
    .split(' ')
    .filter (tok) -> tok and tok.length > 1

bagOfWords = (toks) ->
  v = {}
  for tok in toks
    if v[tok] then v[tok] += 1 else v[tok] = 1
  v

computeTensor = (str, ngramDim = 1) ->
  toks = tokenize(str)
  tensor = for ngramRank in [1..ngramDim]
    bagOfWords(if ngramRank == 1 then toks else ngrams(toks, ngramRank))
  tensor

normBagOfWords = (v1, v2) ->
  keys = (k for k of extend({}, v1, v2))
  ws = for k in keys
    x1 = v1[k] or 0
    x2 = v2[k] or 0
    abs(x1 - x2)

  ret = sumArray(ws)
  ret

sumArray = (ws) ->
  n = 0
  for w in ws
    n += w
  n

norm = (t1, t2) ->
  throw new Error('invalid dimensions') unless t1.length == t2.length
  ws = for a, idx in t1
    b = t2[idx]
    normBagOfWords(a, b) * pow(100, idx)
  ret = sumArray(ws)
  ret

rankSearchResults = (results, query, ngramRank) ->
  queryT = computeTensor(query, ngramRank)
  for result in results
    result.rank = norm(computeTensor(шеуь, ngramRank), queryT)

extend exports, {
  extend, urlencode, xhrGET, uniqueId, isArray,
  rankSearchResults,
  BaseResolver, ResolverSet, Module}

if window?
  window.SongLocator = window.SongLocator or {}
  extend(window.SongLocator, exports)
