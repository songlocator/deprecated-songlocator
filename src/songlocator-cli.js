// Generated by CoffeeScript 1.4.0
/*

  Command line interface for SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>
*/

var ResolverSet;

ResolverSet = require('./songlocator-base').ResolverSet;

exports.parseArguments = function(argv) {
  var arg, args, opts;
  if (argv == null) {
    argv = process.argv;
  }
  argv = argv.splice(2);
  args = [];
  opts = {
    config: void 0,
    resolvers: []
  };
  while (argv.length > 0) {
    arg = argv.shift();
    if (arg === '-c' || args === '--config') {
      opts.config = argv.shift();
    } else if (arg === '--debug') {
      opts.debug = true;
    } else if (arg.substring(0, 6) === '--use-') {
      opts.resolvers.push(arg.substring(6));
    } else {
      args.push(arg);
    }
  }
  return {
    args: args,
    opts: opts
  };
};

exports.main = function() {
  var Resolver, cfg, config, name, query, resolver, resolvers;
  query = process.argv[2] != null ? process.argv[2] : (console.log('error: provide a search query as an argument'), process.exit(1));
  config = {
    youtube: {}
  };
  resolvers = (function() {
    var _results;
    _results = [];
    for (name in config) {
      cfg = config[name];
      Resolver = require("./songlocator-" + name).Resolver;
      _results.push(new Resolver(cfg));
    }
    return _results;
  })();
  resolver = new ResolverSet(resolvers);
  return resolver.searchDebug(query);
};