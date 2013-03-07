###

  SongLocator resolver for SoundCloud.

  2013 (c) Andrey Popp <8mayday@gmail.com>

  Based on Tomahawk YouTube resolver.

  2012 (c) Thierry Göckel <thierry@strayrayday.lu>
###

{BaseResolver, extend} = require './songlocator-base'

capitalize = (s) ->
  s.replace /(^|\s)([a-z])/g , (m, p1, p2) -> p1 + p2.toUpperCase()

unquote = (s) ->
  s.replace('"', '').replace("'", "")

class Resolver extends BaseResolver

  name: 'soundcloud'

  options: extend {consumerKey: 'TiNg2DRYhBnp01DA3zNag'}, BaseResolver::options

  getTrack: (found, orig) ->
    if not this.options.includeCovers \
        and found.search(/cover/i) != -1 \
        and orig.search(/cover/i) == -1
      null
    else if not this.options.includeRemixes \
        and found.search(/(re)*mix/i) != -1 \
        and orig.search(/(re)*mix/i) == -1
      null
    else if not this.options.includeLive \
        and found.search(/live/i) != -1 \
        and orig.search(/live/i) == -1
      null
    else
      found

  betterArtwork: (url) ->
    url.replace('-large', '-t500x500') if url?

  resolve: (qid, track, artist, album) ->
    query = "#{artist} #{track}".trim()

    this.request
      url: 'http://api.soundcloud.com/tracks.json'
      params:
        consumer_key: this.options.consumerKey
        filter: 'streamable'
        q: query

      callback: (error, resp) =>
        return if error?
        return if resp.length == 0

        results = for r in resp
          continue unless r?.streamable

          # Check whether the artist and title (if set) are in the returned
          # title, discard otherwise But also, the artist could be the username
          continue if r.title? and (
              r.title.toLowerCase().indexOf(artist.toLowerCase()) == -1 \
              or r.title.toLowerCase().indexOf(track.toLowerCase()) == -1)

          continue unless this.getTrack(r.title, track)

          result =
            title: track
            artist: artist
            album: undefined

            source: this.name
            id: r.id

            linkURL: r.permalink_url
            imageURL: this.betterArtwork(r.artwork_url)
            audioURL: "#{r.stream_url}.json?client_id=#{this.options.consumerKey}"
            audioPreviewURL: undefined

            mimetype: "audio/mpeg"
            duration: r.duration / 1000

        this.results(qid, [results[0]])

  search: (qid, searchString) ->
    this.request
      url: 'http://api.soundcloud.com/tracks.json'
      params:
        consumer_key: this.options.consumerKey
        filter: 'streamable'
        limit: this.options.searchMaxResults
        q: unquote(searchString)
      callback: (error, resp) =>
        return if error?
        return if resp.length == 0

        results = for r in resp
          continue unless r?
          continue unless this.getTrack(r.title, '')

          result =
            album: undefined

            source: this.name
            id: r.id

            linkURL: r.permalink_url
            imageURL: this.betterArtwork(r.artwork_url)
            audioURL: "#{r.stream_url}.json?client_id=#{this.options.consumerKey}"
            audioPreviewURL: undefined

            mimetype: 'audio/mpeg'
            duration: r.duration / 1000

          track = r.title
          if track.indexOf(" - ") != -1 \
              and track.slice(track.indexOf(" - ") + 3).trim() != ""
            result.title = track.slice(track.indexOf(" - ") + 3).trim()
            result.artist = track.slice(0, track.indexOf(" - ")).trim()
          else if track.indexOf(" -") != -1 \
              and track.slice(track.indexOf(" -") + 2).trim() != ""
            result.title = track.slice(track.indexOf(" -") + 2).trim()
            result.artist = track.slice(0, track.indexOf(" -")).trim()
          else if track.indexOf(": ") != -1 \
              and track.slice(track.indexOf(": ") + 2).trim() != ""
            result.title = track.slice(track.indexOf(": ") + 2).trim()
            result.artist = track.slice(0, track.indexOf(": ")).trim()
          else if track.indexOf("-") != -1 \
              and track.slice(track.indexOf("-") + 1).trim() != ""
            result.title = track.slice(track.indexOf("-") + 1).trim()
            result.artist = track.slice(0, track.indexOf("-")).trim()
          else if track.indexOf(":") != -1 \
              and track.slice(track.indexOf(":") + 1).trim() != ""
            result.title = track.slice(track.indexOf(":") + 1).trim()
            result.artist = track.slice(0, track.indexOf(":")).trim()
          else if track.indexOf("\u2014") != -1 \
              and track.slice(track.indexOf("\u2014") + 2).trim() != ""
            result.title = track.slice(track.indexOf("\u2014") + 2).trim()
            result.artist = track.slice(0, track.indexOf("\u2014")).trim()
          else if r.title != "" and r.user.username != ""
            # Last resort, the artist is the username
            result.title = r.title
            result.artist = r.user.username
          else
            continue

          result

        this.results(qid, results)

extend exports, {Resolver}

if window?
  if not window.SongLocator?
    throw new Error('no songlocator-base module was loaded')
  window.SongLocator.SoundCloud = {}
  extend(window.SongLocator.SoundCloud, exports)
