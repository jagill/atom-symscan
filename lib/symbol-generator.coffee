{Point} = require 'atom'

### Unused, but good reference for the future
VARIABLE_REGEXPS = [
  /^variable\.assignment/,
  /^variable\.parameter/,
  /^entity\.name\.function/,
  /^variable\.parameter\.function/,
  /^meta\.variable\.assignment/,
]
###

BLACKLIST_REGEXP = /// ^ (
  ?: punctuation
   | keyword
   | string
   | comment
   | constant  # Ruby has constant.other.symbol; should keep this?
   | meta\.brace
   | meta\.delimiter
   | storage\.type
   | storage\.modifier
   | support\.function
) ///

wordRegexp = /\w+/g

###*
Return a dictionary of symbols to lists of positions (as a `Point`)
Eg, `{foo: [(0, 0), (0, 40), (3, 5), ...]}`, where `(x, y)` represents
`new Point(x, y)`.
###
exports.parseSymbols = (grammar, text) ->
  tick = Date.now()
  lines = grammar.tokenizeLines(text)
  symbols = {}
  prev = null
  for tokens, linenum in lines
    offset = 0
    for token in tokens
      syms = findSymbolsInToken token
      for symbol in syms
        name = symbol.name
        # FIXME HACK: constructor is a property of symbols already. Bad JS!
        continue if name is 'constructor'
        symbols[name] = [] unless symbols[name]
        symbols[name].push new Point(linenum, offset + symbol.offsetMod)
      offset +=  token.value.length
  console.log "Parsing symbols took #{Date.now() - tick} ms"
  return symbols

# Return an array (possibly empty) of symbols in the token.
# TODO: When possible add definition/assignment info.
findSymbolsInToken = (token) ->
  return [] unless token? and shouldParse token.scopes
  matches = []
  while result = wordRegexp.exec(token.value)
    matches.push name: result[0], offsetMod: result.index
  return matches

shouldParse = (scopes) ->
  for scope in scopes
    return false if BLACKLIST_REGEXP.test(scope)
    # for regexp in BLACKLIST_REGEXPS
    #   return false if regexp.test(scope)

  return true

###*
Given a position (point) and an ordered list of points, find the points in the
list that are immediately before and after the position.  These can be
undefined, for example if there is no point in the list before (or after) the
position.

Return a map {prev:, next:} .
###
exports.findPrevNext = (position, points) ->
  return {} unless points and points.length

  prev = 0
  next = points.length - 1

  # Begin the binary search!
  while next > prev
    middle = (prev + next) // 2
    switch position.compare(points[middle])
      when 0
        prev = next = middle
      when -1
        next = middle
      when 1
        prev = middle + 1

  switch position.compare(points[prev])
    when 0
      return {prev: points[prev-1], next: points[prev+1]}
    when -1
      return {prev: points[prev-1], next: points[prev]}
    when 1
      return {prev: points[prev], next: points[prev+1]}
