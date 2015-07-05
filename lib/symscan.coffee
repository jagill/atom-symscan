SymscanView = require './symscan-view'
{CompositeDisposable, Point, Range} = require 'atom'
{parseSymbols, findPrevNext} = require './symbol-generator'
{SymbolMarks} = require './symbol-marks'

wordRe = /\w+/

# Get word under cursor, if any.
getCurrentWord = ->
  editor = atom.workspace.getActivePaneItem()
  word = editor.getWordUnderCursor()
  # Sometimes the word has weird cruft like '[foo'; clean it up
  match = wordRe.exec(word)
  return match and match[0]

# Return the point corresponding to the end of the word.
# wordBegin:Point is the beginning of the word
# word:String is the word
endOfWord = (wordBegin, word) ->
  return new Point(wordBegin.row, wordBegin.column + word.length)

module.exports = Symscan =
  symscanView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Map of path to symbols; symbols are a map of name to list of positions (Points)
    @symbolIndex = {}
    # Keep track of highlight marks, so we can destroy them properly
    @marks = new SymbolMarks()

    @symscanView = new SymscanView(state.symscanViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @symscanView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable()

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:generate': => @generate()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:firstSymbol': => @firstSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:prevSymbol': => @prevSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:nextSymbol': => @nextSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:markSymbol': => @markSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:clearMarks': => @clearMarks()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:clearAllMarks': => @clearAllMarks()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidStopChanging =>
        console.log "Re-generating for #{editor?.getPath()}"
        @generate editor

    @subscriptions.add atom.workspace.observePanes (pane) =>
      console.log "Got pane Active item", pane.getActiveItem()?.getPath()
      @subscriptions.add pane.onDidChangeActiveItem (item) =>
        console.log "Changed Active item", item.getPath()

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

  generate: (editor) ->
    editor = editor or atom.workspace.getActivePaneItem()
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
    word = getCurrentWord()
    symbols = @_getSymbols word
    editor = atom.workspace.getActivePaneItem()
    currentPos = editor.getCursorBufferPosition()
    prevNext = findPrevNext currentPos, symbols
    if prev
      pos = prevNext.prev
      if pos and currentPos.isLessThanOrEqual(endOfWord(pos, word))
        # We're inside this word, let's actually go to two previous.
        twoPrev = findPrevNext(pos, symbols).prev
        pos = twoPrev or pos
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
    @marks.clear word

  clearAllMarks: ->
    @marks.clearAll()

  markSymbol: ->
    editor = atom.workspace.getActivePaneItem()
    word = getCurrentWord()
    return unless word
    if @marks.has word
      console.log 'Clearing marks for ' + word
      @clearMarks word
      return
    symbols = @_getSymbols word
    @marks.markSymbol editor, word, symbols
