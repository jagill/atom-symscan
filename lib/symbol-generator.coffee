{SymbolIndex} = require './symbols'

###*
Return a dictionary of symbols to lists of positions (as a `Point`)
Eg, `{foo: [(0, 0), (0, 40), (3, 5), ...]}`, where `(x, y)` represents
`new Point(x, y)`.
###
module.exports = class Symbols
  constructor: ->
    @index = new SymbolIndex()

  generate: (editor) ->
    editor = editor or atom.workspace.getActiveTextEditor()
    @index.parse editor.getPath(), editor.getText(), editor.getGrammar()

  retrieve: (word, editor) ->
    return {} unless word
    filepath = editor.getPath()
    unless filepath of @index
      @generate editor
    return @index.findPositions(filepath, word)
