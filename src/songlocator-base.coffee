###

  SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

XMLHttpRequest = XMLHttpRequest or require('xmlhttprequest').XMLHttpRequest

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

class BaseResolver
  extend this.prototype, EventEmitter

  name: undefined

  options:
    includeRemixes: true
    includeCovers: true
    includeLive: true

  constructor: (options) ->
    this.options = extend({}, this.options, options)

  request: (opts) ->
    xhrGET(opts)

  search: (qid, query) ->

  resolve: (qid, track, artist, album) ->

  results: (qid, results) ->
    if results?.length? and results.length > 0
      this.emit('results', {qid: qid, results: results or []})

  searchDebug: (query) ->
    qid = uniqueId('query')
    this.once 'results', (results) ->
      console.log results.results
    this.search(qid, query)

  resolveDebug: (track, artist, album) ->
    qid = uniqueId('resolve')
    this.once 'results', (results) ->
      console.log results.results
    this.resolve(qid, track, artist, album)

if exports?
  extend exports, {extend, urlencode, xhrGET, uniqueId, BaseResolver}
