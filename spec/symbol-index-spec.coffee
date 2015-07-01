{findPrevNext} = require '../lib/symbol-index'
{Point} = require 'atom'

describe 'findPrevNext', ->
  p = null
  beforeEach ->
    p = new Point(2, 4)

  it 'should return nothing when list is empty', ->
    pn = findPrevNext p, []
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next).toBeUndefined("next is #{pn.next}")

  it 'should give nothing when list has only single equal point', ->
    pn = findPrevNext p, [ new Point(2, 4) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next).toBeUndefined("next is #{pn.next}")

  it 'should give only next when list has only single later point', ->
    pn = findPrevNext p, [ new Point(3, 0) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(0)

  it 'should give only next when list is all later points', ->
    pn = findPrevNext p, [ new Point(3, 0), new Point(10, 10) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(0)

  it 'should give only prev when list has only single earlier point', ->
    pn = findPrevNext p, [ new Point(1, 5) ]
    expect(pn.next).toBeUndefined("next is #{pn.next}")
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(5)

  it 'should give only prev when list is all earlier points', ->
    pn = findPrevNext p, [ new Point(1, 0), new Point(1, 5) ]
    expect(pn.next).toBeUndefined("next is #{pn.next}")
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(5)

  it 'should give only prev when final point is position', ->
    pn = findPrevNext p, [ new Point(1, 0), new Point(2, 4) ]
    expect(pn.next).toBeUndefined("next is #{pn.next}")
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(0)

  it 'should give only next when first point is position', ->
    pn = findPrevNext p, [ new Point(2, 4), new Point(3, 6) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(6)

  it 'should give adjacent prev/next when it is in the array', ->
    pn = findPrevNext p, [ new Point(1, 3), new Point(2, 4), new Point(3, 6) ]
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(3)
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(6)

  it 'should give appropriate prev/next when it is not in the array', ->
    pn = findPrevNext p, [ new Point(1, 3), new Point(3, 6) ]
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(3)
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(6)
