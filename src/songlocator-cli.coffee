###

  Command line interface for SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{ResolverSet, rankSearchResults} = require './songlocator-base'
{readFileSync} = require 'fs'

exports.readConfigSync = (filename = './songlocator.json') ->
  try
    JSON.parse readFileSync(filename)
  catch e
    undefined

exports.parseArguments = (argv = process.argv) ->
  argv = argv.splice(2)
  args = []
  opts = {config: undefined, resolvers: []}
  while argv.length > 0
    arg = argv.shift()

    if arg == '-c' or args == '--config'
      opts.config = argv.shift()

    else if arg == '--debug'
      opts.debug = true

    else if arg.substring(0, 6) == '--use-'
      opts.resolvers.push(arg.substring(6))

    else
      args.push(arg)

  {args, opts}

class MyResolverSet extends ResolverSet

  onResults: (results) ->
    return unless results.results.length > 0

    for result in results.results
      console.log result

exports.main = ->

  query = if process.argv[2]?
    process.argv[2]
  else
    console.log 'error: provide a search query as an argument'
    process.exit(1)

  config =
    youtube: {}

  resolvers = for name, cfg of config
    Resolver = require("./songlocator-#{name}").Resolver
    new Resolver(cfg)

  resolver = new MyResolverSet(resolvers)
  resolver.search('1', query)
