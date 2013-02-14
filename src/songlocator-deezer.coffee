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
            title: item.title
            artist: item.artist?.name
            album: item.album?.title

            source: this.name
            id: item.id

            linkURL: item.link
            imageURL: "#{item.album?.cover}?size=big"
            audioURL: undefined
            audioPreviewURL: item.preview

            mimetype: 'audio/mpeg'
            duration: item.duration
          }
        results = results.slice(0, this.options.searchMaxResults)
        this.results(qid, results)

extend exports, {Resolver}

if window?
  if not window.SongLocator?
    throw new Error('no songlocator-base module was loaded')
  window.SongLocator.Deezer = {}
  extend(window.SongLocator.Deezer, exports)
