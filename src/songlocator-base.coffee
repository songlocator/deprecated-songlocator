###

  SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

XMLHttpRequest = XMLHttpRequest or require('xmlhttprequest').XMLHttpRequest
{abs, pow, min} = Math

isArray = Array.isArray or (obj) ->
  toString.call(obj) == '[object Array]'

urlencode = (params) ->
  params = for k, v of params
    "#{k}=#{encodeURIComponent(v.toString())}"
  params.join('&')

xhrPOST = (options) ->
  {url, params, callback, rawResponse} = options
  params = urlencode(params)
  request = new XMLHttpRequest()
  request.open('POST', url, true)
  request.addEventListener 'readystatechange', ->
    if request.readyState == 0
      request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
      request.setRequestHeader('Content-length', params.length)
      request.setRequestHeader('Connection', 'close')
    else if request.readyState == 4
      console.log url, request.status, params
      if request.status == 200
        data = if rawResponse
          request.responseText
        else
          JSON.parse(request.responseText)

        callback(undefined, data)
      else
        callback(request, undefined)

  request.send(params)

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
    searchMaxResults: 10

  constructor: (options = {}) ->
    this.options = extend({}, this.options, options)

  request: (opts) ->
    {method} = opts
    switch (method or 'GET')
      when 'GET' then xhrGET(opts)
      when 'POST' then xhrPOST(opts)
      else throw new Error("unsupported XHR method #{method}")

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
        this.onResults(results)

  onResults: (results) ->
    this.emit('results', results)

  search: (qid, query) ->
    for resolver in this.resolvers
      resolver.search(qid, query)

  resolve: (qid, track, artist, album) ->
    for resolver in this.resolvers
      resolver.resolve(qid, track, artist, album)

tokenNormalizeRe = /[^a-z0-9 ]+/g
spaceNormalizeRe = /[ \t\n]+/g

normalize = (str) ->
  str
    .toLowerCase()
    .replace(tokenNormalizeRe, ' ')
    .replace(spaceNormalizeRe, ' ')

tokenize = (str) ->
  normalize(str)
    .split(' ')
    .filter (tok) -> tok and tok.length > 1

###

  Generate a function to compute a Damerau-Levenshtein distance.

  'prices' customisation of the edit costs by passing an
  object with optional 'insert', 'remove', 'substitute', and
  'transpose' keys, corresponding to either a constant
  number, or a function that returns the cost. The default
  cost for each operation is 1. The price functions take
  relevant character(s) as arguments, should return numbers.

  The damerau flag allows us to turn off transposition and
  only do plain Levenshtein distance.

  Credits goes to http://en.wikipedia.org/wiki/Damerau-Levenshtein_distance
  and Carl Baatz (https://github.com/cbaatz/damerau-levenshtein)

  Licensed under UNLICENSE (http://unlicense.org)

###
damerauLevenshtein = (prices, damerau = true) ->

    prices = prices or {}

    genPriceGetter = (value, defaultPrice = 1) ->
      insert = switch (typeof value)
        when 'function' then value
        when 'number' then -> value
        else -> defaultPrice

    insert = genPriceGetter(prices.insert, 1)
    remove = genPriceGetter(prices.remove, 1)
    substitute = genPriceGetter(prices.substitute, 0.5)
    transpose = genPriceGetter(prices.transpose, 0.2)

    (down, across) ->
      return 0 if down == across

      ds = []

      down = if isArray(down) then down.slice() else down.split('')
      down.unshift(0)
      across = if isArray(across) then across.slice() else across.split('')
      across.unshift(0)

      for d, i in down
        if not ds[i]
          ds[i] = []

        for a, j in across
          if i == 0 and j == 0
            ds[i][j] = 0

          else if i == 0
            # Empty down (i == 0) -> across[1..j] by inserting
            ds[i][j] = ds[i][j-1] + insert(a)

          else if j == 0
            # Down -> empty across (j == 0) by deleting
            ds[i][j] = ds[i-1][j] + remove(d)

          else
            # Find the least costly operation that turns
            # the prefix down[1..i] into the prefix
            # across[1..j] using already calculated costs
            # for getting to shorter matches.
            ds[i][j] = min(
              # Cost of editing down[1..i-1] to
              # across[1..j] plus cost of deleting
              # down[i] to get to down[1..i-1].
              ds[i-1][j] + remove(d),
              # Cost of editing down[1..i] to
              # across[1..j-1] plus cost of inserting
              # across[j] to get to across[1..j].
              ds[i][j-1] + insert(a),
              # Cost of editing down[1..i-1] to
              # across[1..j-1] plus cost of
              # substituting down[i] (d) with across[j]
              # (a) to get to across[1..j].
              ds[i-1][j-1] + (if d == a then 0 else substitute(d, a))
            )

            # Can we match the last two letters of down
            # with across by transposing them? Cost of
            # getting from down[i-2] to across[j-2] plus
            # cost of moving down[i-1] forward and
            # down[i] backward to match across[j-1..j].
            if damerau and i > 1 and j > 1 and down[i-1] == a and d == across[j-1]
              ds[i][j] = min(
                ds[i][j],
                ds[i-2][j-2] + (if d == a then 0 else transpose(d, down[i-1]))
              )

      ds[down.length-1][across.length-1]

rankSearchResults = (results, query, d = {
    tokenize: tokenize,
    distanceGen: damerauLevenshtein}) ->
  qTokens = d.tokenize(query)
  distance = d.distanceGen()

  for result in results
    rank1 = distance(
      d.tokenize("#{result.artist} #{result.track}"),
      qTokens)
    rank2 = distance(
      d.tokenize("#{result.track} #{result.artist}"),
      qTokens)
    result.rank = min(rank1, rank2)

extend exports, {
  extend, urlencode, xhrGET, uniqueId, isArray,
  rankSearchResults, damerauLevenshtein,
  BaseResolver, ResolverSet, Module}

if window?
  window.SongLocator = window.SongLocator or {}
  extend(window.SongLocator, exports)
