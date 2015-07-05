len = (obj) ->
  count = 0
  count += 1 for k of obj
  return count

exports.getGrammar = (extension) ->
  return atom.grammars.selectGrammar('foo.' + extension, '')

exports.expectSymbolLength = (symbols, length) ->
  expect(len(symbols)).toBe length, "Wrong number symbols: " + JSON.stringify(symbols)

exports.expectSymbol = (symbols, name, positions) ->
  foundPositions = symbols[name]
  expect(foundPositions).not.toBe(undefined)
  expect(foundPositions.length).toBe(positions.length)
  for p, i in positions
    fp = foundPositions[i]
    expect(fp.row).toBe p[0]
    expect(fp.column).toBe p[1]
