SymscanView = require './symscan-view'
{CompositeDisposable} = require 'atom'
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
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:prevSymbol': => @prevSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'symscan:nextSymbol': => @nextSymbol()

    # Map of path to symbols; symbols are a map of name to list of positions (Points)
    @symbolIndex = {}

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @symscanView.destroy()

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

  _gotoNextPrevSymbol: (prev=true) ->
    editor = atom.workspace.getActivePaneItem()
    word = getCurrentWord()
    console.log 'WORD ' + word
    return {} unless word
    filepath = editor.getPath()
    unless filepath of @symbolIndex
      @generate()
    symbols = @symbolIndex[filepath][word]
    prevNext = findPrevNext editor.getCursorBufferPosition(), symbols
    if prev
      pos = prevNext.prev
    else
      pos = prevNext.next

    console.log "Moving to " + pos
    editor.setCursorBufferPosition pos if pos


  prevSymbol: ->
    @_gotoNextPrevSymbol true

  nextSymbol: ->
    @_gotoNextPrevSymbol false
