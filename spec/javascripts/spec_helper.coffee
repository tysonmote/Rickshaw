window.setupCustomMatchers = ->
  this.addMatchers {
    # Recurses into nested arrays and objects instead of just doing [] == []
    # (which is false in JavaScript).
    toEqualArray: (expected) ->
      Array._equal( this.actual, expected )

    toBeInstanceOf: (expected) ->
      instanceOf( this.actual, expected )
  }

class window.EventCapture
  constructor: (@object, @event) ->
    @object.addEvent( @event, =>
      @timesFired += 1
      @arguments = Array.from( arguments )
    )
    this.reset()

  reset: ->
    @timesFired = 0
    @arguments = null
