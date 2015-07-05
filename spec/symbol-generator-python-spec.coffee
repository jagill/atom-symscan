{parseSymbols} = require '../lib/symbol-generator'
{getGrammar, expectSymbol, expectSymbolLength} = require './spec-utils'

describe 'parseSymbols', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-python')

  describe 'python', ->
    grammar = null
    beforeEach ->
      grammar = getGrammar 'py'

    it 'should find import variables', ->
      symbols = parseSymbols grammar, "import foo"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'foo', [ [0, 7] ]

    it 'should find import-as variables', ->
      symbols = parseSymbols grammar, "import foo as bar"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'foo', [ [0, 7] ]
      expectSymbol symbols, 'bar', [ [0, 14] ]

    it 'should find import-from variables', ->
      symbols = parseSymbols grammar, "from foo import bar"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'foo', [ [0, 5] ]
      expectSymbol symbols, 'bar', [ [0, 16] ]

    it 'should find simple variable assignment', ->
      symbols = parseSymbols grammar, "ab = 1"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'ab', [ [0, 0] ]

    it 'should find global variable declaration', ->
      symbols = parseSymbols grammar, "global a"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 7] ]

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
      symbols = parseSymbols grammar, "def a():"
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 4] ]

    it 'should find function parameters', ->
      symbols = parseSymbols grammar, "def a(b, c):"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 4] ]
      expectSymbol symbols, 'b', [ [0, 6] ]
      expectSymbol symbols, 'c', [ [0, 9] ]

    it 'should find parameters in called function', ->
      symbols = parseSymbols grammar, "a(b, c)"
      expectSymbolLength symbols, 3
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [0, 2] ]
      expectSymbol symbols, 'c', [ [0, 5] ]

    it 'should find variables in multi-line function bodies', ->
      symbols = parseSymbols grammar, "a = ->\n  c=1\n  return c"
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'c', [ [1, 2], [2, 9] ]

    it 'should ignore comments', ->
      symbols = parseSymbols grammar, 'a = 1 # b = c'
      expectSymbolLength symbols, 1
      expectSymbol symbols, 'a', [ [0, 0] ]

    it 'should ignore booleans', ->
      symbols = parseSymbols grammar, 'a = True\nb = False'
      expectSymbolLength symbols, 2
      expectSymbol symbols, 'a', [ [0, 0] ]
      expectSymbol symbols, 'b', [ [1, 0] ]
