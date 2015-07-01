{Point} = require 'atom'

###*
Given a position (point) and an ordered list of points, find the points in the
list that are immediately before and after the position.  These can be
undefined, for example if there is no point in the list before (or after) the
position.

Return a map {prev:, next:} .
###
exports.findPrevNext = (position, points) ->
  return {} unless points and points.length

  prev = 0
  next = points.length - 1

  # Begin the binary search!
  while next > prev
    middle = (prev + next) // 2
    switch position.compare(points[middle])
      when 0
        prev = next = middle
      when -1
        next = middle
      when 1
        prev = middle + 1

  switch position.compare(points[prev])
    when 0
      return {prev: points[prev-1], next: points[prev+1]}
    when -1
      return {prev: points[prev-1], next: points[prev]}
    when 1
      return {prev: points[prev], next: points[prev+1]}
