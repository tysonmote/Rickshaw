# Reset Rickshaw before each spec.
beforeEach ->
  if window.Rickshaw
    Rickshaw.Templates = {}

# ==================
# = Helper methods =
# ==================

# ============
# = Fixtures =
# ============

window.Fixtures = {}

Fixtures.simpleTodoModel = ->
  @Todo = new Model()
  @todo = new @Todo( num: "one" )

Fixtures.simpleTodoController = ->
  Fixtures.simpleTodoModel.call( this )
  Rickshaw.addTemplate( "todo", "<p class='todo {{klass}}'>{{text}}</p>" )
  @TodoController = new Controller(
    Template: "todo",
    text: -> "##{@model.get( "num" )}",
    klass: -> "number_#{@model.get( "num" )}"
  )
  @todoController = new @TodoController( @todo )

Fixtures.simpleTodoControllerWithDefer = ->
  Fixtures.simpleTodoModel.call( this )
  Rickshaw.addTemplate( "todo", "<p class='todo'>{{num}}</p>" )
  @TodoController = new Controller(
    Template: "todo",
    DeferToModel: ["num"]
  )
  @todoController = new @TodoController( @todo )

Fixtures.simpleTodoControllerWithClickEvent = ->
  Fixtures.simpleTodoModel.call( this )
  Rickshaw.addTemplate( "todo", "<p class='todo {{klass}}'>{{num}}</p>" )
  @TodoController = new Controller({
    Template: "todo"
    DeferToModel: ["num"]
    klass: "neato"
    Events:
      p: click: -> @todoClickArguments = Array.from( arguments )
  })
  @todoController = new @TodoController( @todo )

# ============
# = Matchers =
# ============

window.setupCustomMatchers = ->
  this.addMatchers {
    toBeEmpty: ->
      return this.actual.length == 0

    # Recurses into nested arrays and objects instead of just doing [] == []
    # (which is false in JavaScript).
    toMatchArray: (expected) ->
      return Array._equal( this.actual, expected )

    # Ensures that the given object has the appropriate prototype.
    toBeInstanceOf: (expected) ->
      return instanceOf( this.actual, expected )

    # Matches an exception with a regexp.
    toThrowException: (expected) ->
      exception = null

      try
        this.actual()
      catch e
        exception = e

      if this.isNot
        _not_ = " not "
        result = true
        if exception?.message?.match
          result = !exception.message.match( expected )
      else
        _not_ = " "
        result = false
        if exception?.message?.match
          result = !!exception.message.match( expected )

      this.message = ->
        if exception
          return "\"#{exception.message || exception}\" was raised, but we expected it#{_not_}to match #{expected}."
        else
          return "Expected an exception but got nothing."

      if this.isNot then return !result else return result
  }

# ================
# = EventCapture =
# ================

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
