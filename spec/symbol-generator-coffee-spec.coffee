{parseSymbols} = require '../lib/symbol-generator'
{getGrammar, expectSymbol, expectSymbolLength} = require './spec-utils'

describe 'parseSymbols', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

  describe 'coffeeScript', ->
    grammar = null
    beforeEach ->
      grammar = getGrammar 'coffee'

    it 'should find require variables', ->
      symbols = parseSymbols grammar, "foo = require 'fs'"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'foo', [ [0, 0] ]

    it 'should find deconstructed require variables', ->
      symbols = parseSymbols grammar, "{EventEmitter} = require 'events'"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'EventEmitter', [ [0, 1] ]

    it 'should find simple variable assignment', ->
      symbols = parseSymbols grammar, "ab = 1"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'ab', [ [0, 0] ]

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
      symbols = parseSymbols grammar, "a = ->"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 0] ]

    it 'should find function parameters', ->
      symbols = parseSymbols grammar, "a = (b, c) ->"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 5] ]
      expectSymbol symbols, 'c', [ [0, 8] ]

    it 'should find parameters in called function', ->
      symbols = parseSymbols grammar, "a(b, c)"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 2] ]
      expectSymbol symbols, 'c', [ [0, 5] ]

    it 'should find parameters in called function w/o parens', ->
      symbols = parseSymbols grammar, "a b, c"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 2] ]
      expectSymbol symbols, 'c', [ [0, 5] ]

    it 'should find variables in function bodies', ->
      symbols = parseSymbols grammar, "a = -> c=1; return c"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'c', [ [0, 7], [0, 19] ]

    it 'should find variables in multi-line function bodies', ->
      symbols = parseSymbols grammar, "a = ->\n  c=1\n  return c"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'c', [ [1, 2], [2, 9] ]

    it 'should ignore comments', ->
      symbols = parseSymbols grammar, 'a = 1 # b = c'
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 0] ]

    it 'should ignore block comments', ->
      symbols = parseSymbols grammar, '###\nb\n###'
      expectSymbolLength symbols, 0

    it 'should ignore booleans', ->
      symbols = parseSymbols grammar, 'a = true\nb = false'
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [1, 0] ]
