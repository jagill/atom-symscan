SymscanView = require './symscan-view'
{CompositeDisposable, Point, Range, TextEditor} = require 'atom'
Symbols = require './symbol-generator'
{SymbolMarks} = require './symbol-marks'
utils = require './utils'

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
    @symbols = new Symbols()
    # Keep track of highlight marks, so we can destroy them properly
    @marks = new SymbolMarks(@symbols)

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
        @symbols.generate editor
        @marks.regenerate()

    @subscriptions.add atom.workspace.observePanes (pane) =>
      @subscriptions.add pane.onDidChangeActiveItem (item) =>
        # This can be undefined if the pane closes.
        return unless item and item instanceof TextEditor
        console.log "Pane", pane, "changed Active item", item?.getPath()
        @marks.regenerate()

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
    @symbols.generate editor

  _gotoNextPrevSymbol: (prev=true) ->
    word = getCurrentWord()
    editor = atom.workspace.getActivePaneItem()
    symbols = @symbols.retrieve word, editor
    currentPos = editor.getCursorBufferPosition()
    prevNext = utils.findPrevNext currentPos, symbols
    if prev
      pos = prevNext.prev
      if pos and currentPos.isLessThanOrEqual(endOfWord(pos, word))
        # We're inside this word, let's actually go to two previous.
        twoPrev = utils.findPrevNext(pos, symbols).prev
        pos = twoPrev or pos
    else
      pos = prevNext.next
    editor.setCursorBufferPosition pos if pos

  prevSymbol: ->
    @_gotoNextPrevSymbol true

  nextSymbol: ->
    @_gotoNextPrevSymbol false

  firstSymbol: ->
    word = getCurrentWord()
    editor = atom.workspace.getActivePaneItem()
    symbols = @symbols.retrieve word, editor
    pos = symbols[0]
    editor.setCursorBufferPosition pos if pos

  clearMarks: ->
    word = getCurrentWord()
    @marks.clear word

  clearAllMarks: ->
    @marks.clearAll()

  markSymbol: ->
    word = getCurrentWord()
    return unless word
    if @marks.has word
      console.log 'Clearing marks for ' + word
      @marks.clear word
      return
    @marks.names.push word
    @marks.regenerate()
