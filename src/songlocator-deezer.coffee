###

  SongLocator resolver for Deezer.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{BaseResolver, extend} = require './songlocator-base'

class Resolver extends BaseResolver
  name: 'deezer'
  score: 0.9

  search: (qid, query) ->
    this.request
      url: 'http://api.deezer.com/2.0/search'
      params: {q: query}
      callback: (error, response) =>
        return if error?
        return unless response.data.length > 0

        results = for item in response.data
          {
            artist: item.artist.name
            album: item.album.name
            track: item.title
            linkUrl: item.link
            duration: item.duration
            score: this.score
          }
        this.results(qid, results)

extend exports, {Resolver}

if window?
  if not window.SongLocator?
    throw new Error('no songlocator-base module was loaded')
  window.SongLocator.Deezer = {}
  extend(window.SongLocator.Deezer, exports)
