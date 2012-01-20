window.setupCustomMatchers = ->
  this.addMatchers {
    # Recurses into nested arrays and objects instead of just doing [] == []
    # (which is false in JavaScript).
    toEqualArray: (expected) ->
      Array._equal( this.actual, expected )
  }
