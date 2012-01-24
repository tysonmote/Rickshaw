# Reset Rickshaw before each spec.
beforeEach ->
  if window.Rickshaw
    Rickshaw._objects = {}

window.rickshawTemplate = (name, template) ->
  Rickshaw.Templates[name] = Handlebars.compile( template )

window.setupCustomMatchers = ->
  this.addMatchers {
    # Recurses into nested arrays and objects instead of just doing [] == []
    # (which is false in JavaScript).
    toEqualArray: (expected) ->
      Array._equal( this.actual, expected )

    # Ensures that the given object has the appropriate prototype.
    toBeInstanceOf: (expected) ->
      instanceOf( this.actual, expected )
  }

# Capture MooTools events.
#
#     clickEvent = new EventCapture element, "click"
#     # do stuff
#     clickEvent.arguments # [events...]
#     clickEvent.timesFired # times fired
#     clickEvent.reset() # reset captured args and fire count
#
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
