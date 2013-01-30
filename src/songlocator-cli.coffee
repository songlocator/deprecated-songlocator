###

  Command line interface for SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>

###

{ResolverSet} = require './songlocator-base'

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

  resolver = new ResolverSet(resolvers)
  resolver.searchDebug(query)
