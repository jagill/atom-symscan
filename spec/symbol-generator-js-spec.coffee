{parseSymbols} = require '../lib/symbol-generator'

# TODO: Dedup this code.
getGrammar = (extension) ->
  return atom.grammars.selectGrammar('foo.' + extension, '')

len = (obj) ->
  count = 0
  count += 1 for k, v of obj
  return count

expectSymbolLength = (symbols, length) ->
  expect(len(symbols)).toBe length, "Wrong number symbols: " + JSON.stringify(symbols)

expectSymbol = (symbols, name, positions) ->
  foundPositions = symbols[name]
  expect(foundPositions).not.toBe(undefined)
  expect(foundPositions.length).toBe(positions.length)
  for p, i in positions
    fp = foundPositions[i]
    expect(fp.row).toBe p[0]
    expect(fp.column).toBe p[1]

describe 'parseSymbols', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

  describe 'JavaScript', ->
    grammar = null
    beforeEach ->
      grammar = getGrammar 'js'

    it 'should find simple variable assignment', ->
      symbols = parseSymbols grammar, "ab = 1;"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'ab', [ [0, 0] ]

    it 'should find simple variable declaration', ->
      symbols = parseSymbols grammar, "var a = 1;"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 4] ]

    it 'should find require variables', ->
      symbols = parseSymbols grammar, "foo = require('fs')"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'foo', [ [0, 0] ]

    it 'should find things on additional lines', ->
      symbols = parseSymbols grammar, "0\na = 1"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [1, 0] ]

    it 'should find simple variable assignment and referred value', ->
      symbols = parseSymbols grammar, "a = b"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 4] ]

    it 'should find function definitions', ->
      symbols = parseSymbols grammar, "function a() {}"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 9] ]

    it 'should find function assignments', ->
      symbols = parseSymbols grammar, "a = function () {}"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 0] ]

    it 'should find function parameters', ->
      symbols = parseSymbols grammar, "a = function (b, c) {}"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 14] ]
      expectSymbol symbols, 'c', [ [0, 17] ]

    it 'should find parameters in called function', ->
      symbols = parseSymbols grammar, "a(b, c)"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 2] ]
      expectSymbol symbols, 'c', [ [0, 5] ]

    it 'should find variables in function bodies', ->
      symbols = parseSymbols grammar, "a = function() {c=1; return c;}"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'c', [ [0, 16], [0, 28] ]

    it 'should find variables in multi-line function bodies', ->
      symbols = parseSymbols grammar, "a = function() {\n  c=1;\n  return c;\n}"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'c', [ [1, 2], [2, 9] ]

    it 'should ignore comments', ->
      symbols = parseSymbols grammar, 'a = 1 // b = c'
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 0] ]

    it 'should ignore block comments', ->
      symbols = parseSymbols grammar, '/*\nb\n*/'
      expectSymbolLength symbols, 0

    it 'should ignore booleans', ->
      symbols = parseSymbols grammar, 'a = true\nb = false'
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [1, 0] ]