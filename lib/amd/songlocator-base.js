define(function(require, exports, module) {
// Generated by CoffeeScript 1.4.0
/*

  SongLocator.

  2013 (c) Andrey Popp <8mayday@gmail.com>
*/

var BaseResolver, EventEmitter, Module, ResolverSet, ResolverShortcuts, XMLHttpRequest, abs, damerauLevenshtein, extend, idCounter, isArray, min, normalize, pow, rankSearchResults, spaceNormalizeRe, tokenNormalizeRe, tokenize, uniqueId, urlencode, xhrGET, xhrPOST,
  __slice = [].slice,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

XMLHttpRequest = XMLHttpRequest || require('xmlhttprequest').XMLHttpRequest;

abs = Math.abs, pow = Math.pow, min = Math.min;

isArray = Array.isArray || function(obj) {
  return toString.call(obj) === '[object Array]';
};

urlencode = function(params) {
  var k, v;
  params = (function() {
    var _results;
    _results = [];
    for (k in params) {
      v = params[k];
      _results.push("" + k + "=" + (encodeURIComponent(v.toString())));
    }
    return _results;
  })();
  return params.join('&');
};

xhrPOST = function(options) {
  var callback, params, rawResponse, request, url;
  url = options.url, params = options.params, callback = options.callback, rawResponse = options.rawResponse;
  params = urlencode(params);
  request = new XMLHttpRequest();
  request.open('POST', url, true);
  request.addEventListener('readystatechange', function() {
    var data;
    if (request.readyState === 0) {
      request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
      request.setRequestHeader('Content-length', params.length);
      return request.setRequestHeader('Connection', 'close');
    } else if (request.readyState === 4) {
      console.log(url, request.status, params);
      if (request.status === 200) {
        data = rawResponse ? request.responseText : JSON.parse(request.responseText);
        return callback(void 0, data);
      } else {
        return callback(request, void 0);
      }
    }
  });
  return request.send(params);
};

xhrGET = function(options) {
  var callback, params, rawResponse, request, url;
  url = options.url, params = options.params, callback = options.callback, rawResponse = options.rawResponse;
  url = "" + url + "?" + (urlencode(params));
  request = new XMLHttpRequest();
  request.open('GET', url, true);
  request.addEventListener('readystatechange', function() {
    var data;
    if (request.readyState !== 4) {
      return;
    }
    if (request.status === 200) {
      data = rawResponse ? request.responseText : JSON.parse(request.responseText);
      return callback(void 0, data);
    } else {
      return callback(request, void 0);
    }
  });
  return request.send();
};

extend = function() {
  var k, o, obj, objs, v, _i, _len;
  obj = arguments[0], objs = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  for (_i = 0, _len = objs.length; _i < _len; _i++) {
    o = objs[_i];
    for (k in o) {
      v = o[k];
      obj[k] = v;
    }
  }
  return obj;
};

idCounter = 0;

uniqueId = function(prefix) {
  var id;
  id = ++idCounter + '';
  if (prefix) {
    return prefix + id;
  } else {
    return id;
  }
};

EventEmitter = {
  on: function(name, callback) {
    var handlers, list;
    if (!this.hasOwnProperty("_handlers")) {
      this._handlers = {};
    }
    handlers = this._handlers;
    if (!handlers.hasOwnProperty(name)) {
      handlers[name] = [];
    }
    list = handlers[name];
    return list.push(callback);
  },
  once: function(name, callback) {
    var remove,
      _this = this;
    remove = function() {
      _this.off(name, callback);
      return _this.off(name, remove);
    };
    this.on(name, callback);
    return this.on(name, remove);
  },
  emit: function() {
    var args, handlers, l, list, name, _i, _len, _results;
    name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (!this.hasOwnProperty("_handlers")) {
      return;
    }
    handlers = this._handlers;
    if (!handlers.hasOwnProperty(name)) {
      return;
    }
    list = handlers[name];
    _results = [];
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      l = list[_i];
      if (!l) {
        continue;
      }
      _results.push(l.apply(this, args));
    }
    return _results;
  },
  off: function(name, callback) {
    var handlers, index, list, _results;
    if (!this.hasOwnProperty("_handlers")) {
      return;
    }
    handlers = this._handlers;
    if (!handlers.hasOwnProperty(name)) {
      return;
    }
    list = handlers[name];
    index = list.indexOf(callback);
    if (index < 0) {
      return;
    }
    list[index] = false;
    if (index === list.length - 1) {
      _results = [];
      while (index >= 0 && !list[index]) {
        list.length--;
        _results.push(index--);
      }
      return _results;
    }
  }
};

EventEmitter.addListener = EventEmitter.on;

EventEmitter.addEventListener = EventEmitter.on;

EventEmitter.removeListener = EventEmitter.off;

EventEmitter.removeEventListener = EventEmitter.off;

EventEmitter.trigger = EventEmitter.emit;

Module = (function() {

  function Module() {}

  Module.include = function() {
    var mixin, mixins, _i, _len, _results;
    mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    _results = [];
    for (_i = 0, _len = mixins.length; _i < _len; _i++) {
      mixin = mixins[_i];
      _results.push(extend(this.prototype, mixin));
    }
    return _results;
  };

  return Module;

})();

ResolverShortcuts = {
  searchDebug: function(query) {
    var qid;
    qid = uniqueId('query');
    this.once('results', function(results) {
      return console.log(results.results);
    });
    this.search(qid, query);
  },
  resolveDebug: function(track, artist, album) {
    var qid;
    qid = uniqueId('resolve');
    this.once('results', function(results) {
      return console.log(results.results);
    });
    this.resolve(qid, track, artist, album);
  }
};

BaseResolver = (function(_super) {

  __extends(BaseResolver, _super);

  BaseResolver.include(EventEmitter, ResolverShortcuts);

  BaseResolver.prototype.name = void 0;

  BaseResolver.prototype.options = {
    includeRemixes: true,
    includeCovers: true,
    includeLive: true,
    searchMaxResults: 10
  };

  function BaseResolver(options) {
    if (options == null) {
      options = {};
    }
    this.options = extend({}, this.options, options);
  }

  BaseResolver.prototype.request = function(opts) {
    var method;
    method = opts.method;
    switch (method || 'GET') {
      case 'GET':
        return xhrGET(opts);
      case 'POST':
        return xhrPOST(opts);
      default:
        throw new Error("unsupported XHR method " + method);
    }
  };

  BaseResolver.prototype.search = function(qid, query) {
    throw new Error('not implemented');
  };

  BaseResolver.prototype.resolve = function(qid, track, artist, album) {
    var query;
    query = (artist || '') + (track || '');
    return this.search(qid, query.trim());
  };

  BaseResolver.prototype.results = function(qid, results) {
    if (((results != null ? results.length : void 0) != null) && results.length > 0) {
      return this.emit('results', {
        qid: qid,
        results: results
      });
    }
  };

  return BaseResolver;

})(Module);

ResolverSet = (function(_super) {

  __extends(ResolverSet, _super);

  ResolverSet.include(EventEmitter, ResolverShortcuts);

  function ResolverSet() {
    var resolver, resolvers, _i, _len, _ref,
      _this = this;
    resolvers = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.resolvers = isArray(resolvers[0]) ? resolvers[0] : resolvers;
    _ref = this.resolvers;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      resolver = _ref[_i];
      resolver.on('results', function(results) {
        return _this.onResults(results);
      });
    }
  }

  ResolverSet.prototype.onResults = function(results) {
    return this.emit('results', results);
  };

  ResolverSet.prototype.search = function(qid, query) {
    var resolver, _i, _len, _ref, _results;
    _ref = this.resolvers;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      resolver = _ref[_i];
      _results.push(resolver.search(qid, query));
    }
    return _results;
  };

  ResolverSet.prototype.resolve = function(qid, track, artist, album) {
    var resolver, _i, _len, _ref, _results;
    _ref = this.resolvers;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      resolver = _ref[_i];
      _results.push(resolver.resolve(qid, track, artist, album));
    }
    return _results;
  };

  return ResolverSet;

})(Module);

tokenNormalizeRe = /[^a-z0-9 ]+/g;

spaceNormalizeRe = /[ \t\n]+/g;

normalize = function(str) {
  return str.toLowerCase().replace(tokenNormalizeRe, ' ').replace(spaceNormalizeRe, ' ');
};

tokenize = function(str) {
  return normalize(str).split(' ').filter(function(tok) {
    return tok && tok.length > 1;
  });
};

/*

  Generate a function to compute a Damerau-Levenshtein distance.

  'prices' customisation of the edit costs by passing an
  object with optional 'insert', 'remove', 'substitute', and
  'transpose' keys, corresponding to either a constant
  number, or a function that returns the cost. The default
  cost for each operation is 1. The price functions take
  relevant character(s) as arguments, should return numbers.

  The damerau flag allows us to turn off transposition and
  only do plain Levenshtein distance.

  Credits goes to http://en.wikipedia.org/wiki/Damerau-Levenshtein_distance
  and Carl Baatz (https://github.com/cbaatz/damerau-levenshtein)

  Licensed under UNLICENSE (http://unlicense.org)
*/


damerauLevenshtein = function(prices, damerau) {
  var genPriceGetter, insert, remove, substitute, transpose;
  if (damerau == null) {
    damerau = true;
  }
  prices = prices || {};
  genPriceGetter = function(value, defaultPrice) {
    var insert;
    if (defaultPrice == null) {
      defaultPrice = 1;
    }
    return insert = (function() {
      switch (typeof value) {
        case 'function':
          return value;
        case 'number':
          return function() {
            return value;
          };
        default:
          return function() {
            return defaultPrice;
          };
      }
    })();
  };
  insert = genPriceGetter(prices.insert, 1);
  remove = genPriceGetter(prices.remove, 1);
  substitute = genPriceGetter(prices.substitute, 0.5);
  transpose = genPriceGetter(prices.transpose, 0.2);
  return function(down, across) {
    var a, d, ds, i, j, _i, _j, _len, _len1;
    if (down === across) {
      return 0;
    }
    ds = [];
    down = isArray(down) ? down.slice() : down.split('');
    down.unshift(0);
    across = isArray(across) ? across.slice() : across.split('');
    across.unshift(0);
    for (i = _i = 0, _len = down.length; _i < _len; i = ++_i) {
      d = down[i];
      if (!ds[i]) {
        ds[i] = [];
      }
      for (j = _j = 0, _len1 = across.length; _j < _len1; j = ++_j) {
        a = across[j];
        if (i === 0 && j === 0) {
          ds[i][j] = 0;
        } else if (i === 0) {
          ds[i][j] = ds[i][j - 1] + insert(a);
        } else if (j === 0) {
          ds[i][j] = ds[i - 1][j] + remove(d);
        } else {
          ds[i][j] = min(ds[i - 1][j] + remove(d), ds[i][j - 1] + insert(a), ds[i - 1][j - 1] + (d === a ? 0 : substitute(d, a)));
          if (damerau && i > 1 && j > 1 && down[i - 1] === a && d === across[j - 1]) {
            ds[i][j] = min(ds[i][j], ds[i - 2][j - 2] + (d === a ? 0 : transpose(d, down[i - 1])));
          }
        }
      }
    }
    return ds[down.length - 1][across.length - 1];
  };
};

rankSearchResults = function(results, query, d) {
  var distance, qTokens, rank1, rank2, result, _i, _len, _results;
  if (d == null) {
    d = {
      tokenize: tokenize,
      distanceGen: damerauLevenshtein
    };
  }
  qTokens = d.tokenize(query);
  distance = d.distanceGen();
  _results = [];
  for (_i = 0, _len = results.length; _i < _len; _i++) {
    result = results[_i];
    rank1 = distance(d.tokenize("" + result.artist + " " + result.track), qTokens);
    rank2 = distance(d.tokenize("" + result.track + " " + result.artist), qTokens);
    _results.push(result.rank = min(rank1, rank2));
  }
  return _results;
};

extend(exports, {
  extend: extend,
  urlencode: urlencode,
  xhrGET: xhrGET,
  uniqueId: uniqueId,
  isArray: isArray,
  rankSearchResults: rankSearchResults,
  damerauLevenshtein: damerauLevenshtein,
  BaseResolver: BaseResolver,
  ResolverSet: ResolverSet,
  Module: Module
});

if (typeof window !== "undefined" && window !== null) {
  window.SongLocator = window.SongLocator || {};
  extend(window.SongLocator, exports);
}
});
