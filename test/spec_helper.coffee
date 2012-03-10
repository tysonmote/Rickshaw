window.resetRickshaw = ->
  $( "test" ).innerHTML = ""
  Rickshaw.Templates = {}

# ==============
# = Assertions =
# ==============

Assertion = expect.Assertion

Assertion::matchArray = (expected) ->
  this.assert(
    Array._equal( this.obj, expected ),
    "expected #{this.obj} to match array #{expected}",
    "expected #{this.obj} not to match array #{expected}"
  )

Assertion::instanceOf = (expected) ->
  this.assert(
    instanceOf( this.obj, expected ),
    "expected #{this.obj} to be an instance of #{expected}",
    "expected #{this.obj} not to be an instance of #{expected}",
  )

Assertion::called = ->
  spy = this.obj
  this.assert(
    spy.called,
    "expected #{spy} to be called, but it wasn't",
    "expected #{spy} not to be called, but it was called with #{spy.args}"
  )

Assertion::calledWith = (expected) ->
  spy = this.obj
  this.assert(
    spy.called and spy.calledWith( expected ),
    "expected #{spy} to be called with #{expected}, but it wasn't",
    "expected #{spy} not to be called with #{expected}, but it was"
  )

Assertion::calledOnce = ->
  spy = this.obj
  this.assert(
    spy.callCount == 1,
    "expected #{spy} to be called once, but it was called #{spy.callCount} times",
    "expected #{spy} not to be called once, but it was"
  )

# ============
# = Fixtures =
# ============

window.Fixtures = Fixtures = {}

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
class EventCapture
  constructor: (@object, @event) ->
    @object.addEvent( @event, =>
      @timesFired += 1
      @arguments = Array.from( arguments )
    )
    this.reset()

  reset: ->
    @timesFired = 0
    @arguments = null

window.EventCapture = EventCapture
