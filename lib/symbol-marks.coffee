{Point, Range} = require 'atom'

# Return the point corresponding to the end of the word.
# wordBegin:Point is the beginning of the word
# word:String is the word
# XXX: Duplicate code, extract
endOfWord = (wordBegin, word) ->
  return new Point(wordBegin.row, wordBegin.column + word.length)

exports.SymbolMarks = class SymbolMarks
  constructor: ->
    # marks = name:{color:, paths:{path:[marks]}}
    @marks = {}
    # TODO Colors

  _destroy: (name, path) ->
    marks = @marks[name]?.paths[path]
    return unless marks
    mark.destroy() for mark in marks

  clear: (name) ->
    return unless name of @marks
    for path of @marks[name].paths
      @_destroy name, path
    delete @marks[name]

  clearAll: ->
    for name of @marks
      @clear name

  has: (name) ->
    return name of @marks

  markSymbol: (editor, name, symbols) ->
    # XXX: Do we need to watch out for name=='constructor' here?
    path = editor.getPath()
    symbolMarks = []
    for pos in symbols
      endPos = endOfWord pos, name
      range = new Range(pos, endPos)
      marker = editor.markBufferRange(range)
      decoration = editor.decorateMarker(marker,
            {type: 'highlight', class: 'highlight-selected'})
      symbolMarks.push marker

    @marks[name] = {paths:{}} unless name of @marks
    if path of @marks[name].paths
      @_destroy name, path
    @marks[name].paths[path] = symbolMarks
