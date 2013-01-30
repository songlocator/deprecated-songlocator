###

  SongLocator resolver for YouTube.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{BaseResolver} = require './songlocator-base'

regexIndexOf = (s, regex, startpos) ->
  indexOf = s.substring(startpos || 0).search(regex)
  return if indexOf >= 0 then indexOf + (startpos || 0) else indexOf

class exports.Resolver extends BaseResolver
  name: 'youtube'

  search: (qid, query) ->
    url = 'http://gdata.youtube.com/feeds/api/videos/'
    params = {alt: 'jsonc', q: query, 'max-results': 10, v: 2}
    this.request
      url: url
      params: params
      callback: (error, response) =>
        return if error
        return if response.data.totalItems == 0
        results = for item in response.data.items
          result = this.item2result(item, query)
          continue unless result?
          result
        this.results(qid, results)

  resolve: (qid, song, artist, album) ->
    query = [artist or '', song or ''].join(' ').trim()
    this.search(qid, query)

  item2result: (item, query) ->
    return unless item.title and item.duration and not item.contentRating
    return unless this.dirtyCheckTitle(item.title, query)

    parsedTrack = this.cleanupAndParseTrack(item.title, query)

    return if not parsedTrack or not parsedTrack.artist?

    if this.getTrack(item.title, query, true)
      result = {}
      result.source = this.name
      result.mimetype = "video/h264"
      result.duration = item.duration
      result.score = if parsedTrack.isOfficial? then 0.85 else 0.95
      result.year = item.uploaded.slice(0,4)
      result.url = item.player['default']
      result.query = query
      result.artist = parsedTrack.artist
      result.track = parsedTrack.track
      result.linkUrl = item.player['default'] + '&hd=1'

    result

  dirtyCheckTitle: (title, query) ->
    # dirty check, filters out the most of the unwanted results
    titleItem = title
      .replace(/([^A-Za-z0-9\s])/gi, "")
      .replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,'')
      .replace(/\s+/g,'|');
    queryItem = query
      .replace(/([^A-Za-z0-9\s])/gi, "")
      .replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,'')
      .replace(/\s+/g,'|');
    matches = titleItem.match(RegExp(queryItem, 'gi'))

    matches and matches.length == queryItem.split("|").length

  cleanupAndParseTrack: (title, query) ->
    result = {}

    # For the ease of parsing, remove these
    # Maybe we could up the score a bit?
    if regexIndexOf(title, /(?:[([](?=(official))).*?(?:[)\]])|(?:(official|video)).*?(?:(video))/i, 0 ) != -1
      title = title.replace(/(?:[([](?=(official|video))).*?(?:[)\]])/gi, "")
      title = title.replace(/(official|video(?:([!:-])))/gi, "")
      result.isOfficial = 1

    result.query = title

    # Sometimes users separate titles with quotes :
    # eg, "\"Young Forever\" Jay Z | Mr. Hudson (OFFICIAL VIDEO)"
    # this will parse out the that title
    inQuote = title.match(/([""'])(?:(?=(\\?))\2.).*\1/g);

    if inQuote and inQuote != undefined
      result.track = inQuote[0].substr(1, inQuote[0].length-2)
      title = title.replace(inQuote[0],'')
      result.fromQuote = result.track

      result.parsed = this.parseCleanTrack( title )

      if result.parsed
        result.parsed.track = result.track
        return result.parsed

    else
      result.parsed = this.parseCleanTrack(title)
      if result.parsed
        return result.parsed

    # Still no luck, lets go deeper
    if !result.parsed
      if title.toLowerCase().indexOf(query.toLowerCase()) != -1
        result.parsed = this.parseCleanTrack(title.replace(RegExp(query, "gi"), query.concat(" :")))
      else
        tryMatch = query.replace(/(?:[-|:&])/g, " ")
        if title.toLowerCase().indexOf(tryMatch.toLowerCase()) != -1
          replaceWith = if regexIndexOf(title, /(?:[-|:&])/g, 0) != -1
            query
          else
            query.concat(" : ")
          result.parsed = this.parseCleanTrack( title.replace(RegExp(tryMatch, "gi"), replaceWith))

    if result.fromQuote and result.fromQuote != undefined
      if result.parsed
        result.artist = result.parsed.artist
      result.track = result.fromQuote

    else if result.parsed
      if result.parsed.artist != undefined
        result.artist = result.parsed.artist
      if result.parsed.track != undefined
        result.track = result.parsed.track

    delete result.parsed
    result

  parseCleanTrack: (track) ->
    result = {}
    result.query = track
    result.query.replace /.*?(?=([-:|]\s))/g, (param) ->
      if param != ""
        if result.artist == undefined
          result.artist = param
        else
          if result.track == undefined
            result.track = param

    result.query.replace /(?=([-:|]\s)).*/g, (param) ->
      if param != ""
        if regexIndexOf(param, /([-|:]\s)/g, 0) == 0
          if result.track == undefined
            result.track = param.replace(/([-|:]\s)/g, "")
        else
          if tyresult.artist == undefined
            result.artist = param
          result.track = result.replace(/([-|:]\s)/g, "")

    if result.track != undefined and result.artist != undefined
      # Now, lets move featuring to track title, where it belongs
      ftmatch = result.artist.match(/(?:(\s)(?=(feat.|feat|ft.|ft|featuring)(?=(\s)))).*/gi)
      if ftmatch
        result.artist = result.artist.replace(ftmatch, "")
        result.track += " " + ftmatch

      # Trim
      result.track = result.track.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,'').replace(/\s+/g,' ')
      result.artist = result.artist.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,'').replace(/\s+/g,' ')
      return result

    return

  getTrack: (trackTitle, origTitle, isSearch) ->
    if (this.options.includeCovers == false or this.options.includeCovers == undefined) \
        and trackTitle.search(/(\Wcover(?!(\w)))/i) != -1 \
        and origTitle.search(/(\Wcover(?!(\w)))/i) == -1
      return

    # Allow remix:es in search results?
    if isSearch == undefined
      if (this.options.includeRemixes == false or this.options.includeRemixes == undefined) \
          and trackTitle.search(/(\W(re)*?mix(?!(\w)))/i) != -1 \
          and origTitle.search(/(\W(re)*?mix(?!(\w)))/i) == -1
        return

    if (this.options.includeLive == false or this.options.includeLive == undefined) \
        and trackTitle.search(/(live(?!(\w)))/i) != -1 \
        and origTitle.search(/(live(?!(\w)))/i) == -1
      return

    else
      return trackTitle
