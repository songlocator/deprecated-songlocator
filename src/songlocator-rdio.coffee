###

  SongLocator resolver for rdio.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{BaseResolver, extend} = require './songlocator-base'

class Resolver extends BaseResolver
  name: 'rdio'
  score: 0.9

  search: (qid, query) ->
    this.request
      method: 'POST'
      url: 'http://api.rdio.com/1/'
      params: {method: 'search', query: query, types: 'Track'}
      callback: (error, response) =>
        return if error?
        return unless response.data.length > 0

        console.log response

extend exports, {Resolver}

if window?
  if not window.SongLocator?
    throw new Error('no songlocator-base module was loaded')
  window.SongLocator.Rdio = {}
  extend(window.SongLocator.Rdio, exports)

