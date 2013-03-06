# SongLocator

SongLocator is an architecture for resolving song metadata to audio streams.
This is hugely inspired by Playdar and then Tomahawk.

## Motivation

SongLocator aims to provide a set of modular tools ranging from client side
libraries to API servers to resolve music metadata to audio streams. This should
allow any application with different requirements to embed music and to play it
without actually knowing where it is available from.

There will be a public server soon with an easy to use API.

## Protocol

Resolver has two methods:

* `Resolver.resolve(qid, name, artist, album)`

  Start resolving a song by `name` and optionally `artist` and `album`.

  There will be one or more `results` event triggered when some results are
  available.

  Argument `qid` is an unique identifier of a resolve query. You should use it
  `results` listener to distinguish results from different queries.

* `Resolver.search(qid, query)`

  Start searching for a song using a `query`.

  There will be one or more `results` event triggered when some results are
  available.

  Argument `qid` is an unique identifier of a search query. You should use it
  `results` listener to distinguish results from different queries.

Resolver implements `EventEmmiter` interface (same as from Node.js standard
library) and triggers `results` event when results from some query is available.

The example usage is:

    var qid = // generate qid...
    resolver.search(qid, 'andy stott cherry eye');
    resolver.addListener('results', function(results) {
      if (results.qid !== qid) {
        return; // results for different query
      }
      var result;
      for (var i = 0; length = results.results.length; i < length; i++) {
        result = results.results[i];
        console.log(result.title + ' by ' + result.artist);
      }
    });

Results have a form of

    {
      qid: "qid736383",  // qid used for corresponding resolve() or search() call
      results: [ ...  ]
    }

where single result has a form of

    {
      // song metadata
      title: "Cherry Eye",
      artist: "Andy Stott",
      album: "Some Album",    // optional

      // source
      source: "youtube",      // source from which stream was resolved from
      id: "...",              // id of a stream (dependent on source)

      // links
      linkURL: "...",         // optional link for a song, e.g. SoundCloud page
      imageURL: "...",        // optional link for a song image/cover
      audioURL: "...",        // optional link for a full audio stream
      audioPreviewURL: "...", // optional link for a preview audio stream

      // stream metadata
      mimetype: "...",        // optional mimetype, e.g. video/h264, audio/mpeg
      duration: "187",        // optional duration in seconds
    }
