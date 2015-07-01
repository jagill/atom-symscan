{Point} = require 'atom'

VARIABLE_REGEXPS = [
  /^variable\.assignment/,
  /^variable\.parameter/,
  /^entity\.name\.function/,
  /^variable.parameter.function/,
]

BLACKLIST_REGEXPS = [
  /^punctuation/,
  /^keyword/,
  /^string/,
  /^comment/,
  /^constant/,
  /^meta.brace/,
  /^meta.delimiter/,
  /^storage.type/,
  /^storage.modifier/,
  /^support.function/,
]

wordRegexp = /\w+/g

###*
Return a dictionary of symbols to lists of positions (as a `Point`)
Eg, `{foo: [(0, 0), (0, 40), (3, 5), ...]}`, where `(x, y)` represents
`new Point(x, y)`.
###
exports.parseSymbols = (grammar, text) ->
  lines = grammar.tokenizeLines(text)
  symbols = {}
  prev = null
  for tokens, linenum in lines
    offset = 0
    for token in tokens
      syms = findSymbolsInToken token
      for symbol in syms
        # console.log "SYMBOL " + JSON.stringify(symbol)
        name = symbol.name
        # HACK: constructor is a property of symbols already. Bad JS!
        continue if name is 'constructor'
        symbols[name] = [] unless symbols[name]
        symbols[name].push new Point(linenum, offset + symbol.offsetMod)
      offset +=  token.value.length
  # console.log 'PARSED SYMBOLS', symbols
  return symbols

# Return an array (possibly empty) of symbols in the token.
findSymbolsInToken = (token) ->
  return [] unless token? and shouldParse token.scopes
  matches = []
  while result = wordRegexp.exec(token.value)
    matches.push name: result[0], offsetMod: result.index
  return matches

# This will be messy and hacky at first, will clean it up when we know how.
shouldParse = (scopes) ->
  # lastScope = scopes[scopes.length - 1]
  # if /^meta\.variable\.assignment\.destructured/.test(lastScope)
  #   # This skips ', ' in destructuring, but doesn't skip destructured vars
  #   return 'skip'
  for scope in scopes
    for regexp in BLACKLIST_REGEXPS
      # console.log "Scope #{scope} in regexp #{regexp}: #{regexp.test(scope)}"
      return false if regexp.test(scope)

  return true
