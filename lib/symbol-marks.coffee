{Point, Range} = require 'atom'

# Return the point corresponding to the end of the word.
# wordBegin:Point is the beginning of the word
# word:String is the word
# XXX: Duplicate code, extract
endOfWord = (wordBegin, word) ->
  return new Point(wordBegin.row, wordBegin.column + word.length)

exports.SymbolMarks = class SymbolMarks
  constructor: (@symbols) ->
    # Names are the list of names we want to mark.  This is the point of truth.
    # TODO Colors
    @names = []
    # These are the actual UI marks used; we generate this from @names.
    # marks = name:{color:, paths:{path:[marks]}}
    @marks = {}

  _removeName: (name) ->
    index = @names.indexOf name
    @names.splice(index, 1) if index > -1

  clear: (name) ->
    return unless name of @marks
    mark.destroy() for mark in @marks[name]
    delete @marks[name]
    @_removeName name

  clearAll: ->
    for name of @marks
      @clear name

  # Do we have marks for the given name
  has: (name) ->
    return @names.indexOf(name) > -1

  mark: (name) ->
    symbolMarks = []
    for pane in atom.workspace.getPanes()
      editor = pane.getActiveItem()
      continue unless editor
      symbols = @symbols.retrieve name, editor
      for pos in symbols
        endPos = endOfWord pos, name
        range = new Range(pos, endPos)
        marker = editor.markBufferRange(range)
        decoration = editor.decorateMarker(marker,
              {type: 'highlight', class: 'highlight-selected'})
        symbolMarks.push marker

    if name of @marks
      mark.destroy() for mark in @marks[name]

    @marks[name] = symbolMarks

  regenerate: ->
    @mark name for name in @names
