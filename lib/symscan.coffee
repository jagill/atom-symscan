SymscanView = require './symscan-view'
{CompositeDisposable, Point, Range} = require 'atom'
{parseSymbols} = require './symbol-generator'
{findPrevNext} = require './symbol-index'

wordRe = /\w+/

getCurrentWord = ->
  editor = atom.workspace.getActivePaneItem()
  word = editor.getWordUnderCursor()
  # Sometimes the word has weird cruft like '[foo'; clean it up
  match = wordRe.exec(word)
  return match and match[0]

module.exports = Symscan =
  symscanView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @symscanView = new SymscanView(state.symscanViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @symscanView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:generate': => @generate()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:firstSymbol': => @firstSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:prevSymbol': => @prevSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:nextSymbol': => @nextSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:markSymbol': => @markSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:clearMarks': => @clearMarks()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:clearAllMarks': => @clearAllMarks()

    # Map of path to symbols; symbols are a map of name to list of positions (Points)
    @symbolIndex = {}
    # Keep track of highlight marks, so we can destroy them properly
    @marks = {}

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @symscanView.destroy()
    @clearAllMarks()

  serialize: ->
    symscanViewState: @symscanView.serialize()

  showTags: ->
    console.log 'Show tags'
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  generate: ->
    editor = atom.workspace.getActivePaneItem()
    filepath = editor.getPath()
    symbols = parseSymbols editor.getGrammar(), editor.getText()
    @symbolIndex[filepath] = symbols

  _getSymbols: (word) ->
    editor = atom.workspace.getActivePaneItem()
    word = word or getCurrentWord()
    return {} unless word
    filepath = editor.getPath()
    unless filepath of @symbolIndex
      @generate()
    return @symbolIndex[filepath][word]

  _gotoNextPrevSymbol: (prev=true) ->
    symbols = @_getSymbols()
    editor = atom.workspace.getActivePaneItem()
    prevNext = findPrevNext editor.getCursorBufferPosition(), symbols
    if prev
      pos = prevNext.prev
    else
      pos = prevNext.next
    editor.setCursorBufferPosition pos if pos

  prevSymbol: ->
    @_gotoNextPrevSymbol true

  nextSymbol: ->
    @_gotoNextPrevSymbol false

  firstSymbol: ->
    symbols = @_getSymbols()
    pos = symbols[0]
    editor = atom.workspace.getActivePaneItem()
    editor.setCursorBufferPosition pos if pos

  clearMarks: (word) ->
    word = word or getCurrentWord()
    return unless word of @marks
    for mark in @marks[word]
      mark.destroy()
    delete @marks[word]

  clearAllMarks: ->
    @clearMarks(word) for word of @marks

  markSymbol: ->
    editor = atom.workspace.getActivePaneItem()
    word = getCurrentWord()
    return unless word
    if word of @marks
      @clearMarks word
      return
    @marks[word] = []
    symbols = @_getSymbols word
    for pos in symbols
      endPos = new Point(pos.row, pos.column + word.length)
      range = new Range(pos, endPos)
      marker = editor.markBufferRange(range)
      decoration = editor.decorateMarker(marker,
            {type: 'highlight', class: 'highlight-selected'})
      @marks[word].push marker
