require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Controller", ->
  beforeEach setupCustomMatchers

  describe "creating", ->
    beforeEach Fixtures.simpleTodoController

    it "has an associated model", ->
      expect( @todoController.model ).toBe( @todo )

    it "can be created without a model", ->
      todoController = new @TodoController()
      expect( todoController.model ).toBeNull()
      # and add model later
      expect( todoController.setModel( @todo ) ).toBe( todoController )
      expect( todoController.model ).toBe( @todo )

    it "is not rendered anywhere", ->
      expect( @todoController.rendered ).toBeFalsy()
      expect( $$( "p.todo" ) ).toBeEmpty()

  describe "preattached events", ->
    it "attaches on initialize", ->
      MyController = new Controller( onCoolEvent: -> )
      controller = new MyController()
      event = new EventCapture controller, "coolEvent"
      controller.fireEvent( "coolEvent", [1, "cool"] )
      expect( event.timesFired ).toBe( 1 )
      expect( event.arguments ).toMatchArray( [1, "cool"] )

  describe "model events", ->
    beforeEach Fixtures.simpleTodoController
    beforeEach ->
      # TODO: We shouldn't need to spy on a private method here.
      spyOn( @todoController, "_modelChanged" ).andCallThrough()
      @todoController.setModel( @todo )
      @todoController._modelChanged.reset()

    it "binds events to the model", ->
      @todo.set neat: true, rad: true
      expect( @todoController._modelChanged.callCount ).toBe( 1 )
      expect( @todoController._modelChanged.argsForCall[0] ).toMatchArray( [@todo, ["neat", "rad"]] )

    it "removes the events when setting a new model", ->
      @todo2 = new @Todo()
      @todoController.setModel( @todo2 )
      @todo.set sweet: true
      expect( @todoController._modelChanged ).not.toHaveBeenCalled()

  describe "defer to model", ->
    beforeEach Fixtures.simpleTodoControllerWithDefer

    it "should be able to defer methods to the model", ->
      expect( @todoController.num() ).toEqual( "one" )

  describe "rendering", ->
    beforeEach Fixtures.simpleTodoControllerWithClickEvent

    it "doesn't render without a destination", ->
      expect( @todoController.render() ).toBe( false )
      expect( $$( "p.todo" ) ).toBeEmpty()

    it "renders to a destination (bottom by default)", ->
      $( "test" ).set( "html", "<div id='wrap'><span>1</span></div>")
      expect( @todoController.renderTo( $( "wrap" ) ) ).toBe( true )
      expect( @todoController.rendered ).toBe( true )
      expect( $( "test" ).innerHTML ).toMatch( /<div id="wrap"><span>\d+<\/span><script id="metamorph-\d+-start" type="text\/x-placeholder"><\/script><p class="todo neato">one<\/p><script id="metamorph-\d+-end" type="text\/x-placeholder"><\/script><\/div>/ )

    it "renders to the top of a destination", ->
      $( "test" ).set( "html", "<div id='wrap'><span>1</span></div>")
      expect( @todoController.renderTo( $( "wrap" ), "top" ) ).toBe( true )
      expect( @todoController.rendered ).toBe( true )
      expect( $( "test" ).innerHTML ).toMatch( /<div id="wrap"><script id="metamorph-\d+-start" type="text\/x-placeholder"><\/script><p class="todo neato">one<\/p><script id="metamorph-\d+-end" type="text\/x-placeholder"><\/script><span>\d+<\/span><\/div>/ )

    it "renders on creation when passed an element", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      expect( $( "test" ).innerHTML ).toMatch( /<p class="todo neato">one<\/p>/ )
      expect( todoController.rendered ).toBe( true )

    it "renders HTML to multiple locations simultaneously", ->
      @todoController.renderTo( $( "test" ) )
      @todoController.renderTo( $( "test" ) )
      expect( $( "test" ).innerHTML ).toMatch( /(<p class="todo neato">one<\/p>.+){2}/ )
      expect( @todoController.rendered ).toBe( true )

    it "re-renders when the model changes", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      @todo.set( "num", "two" )
      expect( $$( "#test p" )[0].innerHTML ).toEqual( "two" )
      expect( todoController.rendered ).toBe( true )

  describe "events", ->
    beforeEach Fixtures.simpleTodoControllerWithClickEvent

    it "attaches element events on render", ->
      @todoController.renderTo( $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom." )
      expect( @todoController.todoClickArguments ).toMatchArray( ["Boom.", $$( "#test p" )[0], @todoController.views[0]] )

    it "doesn't attach element events if `_useRelayedEvents` is true", ->
      throw new Error "TODO: fix"
      @todoController._useRelayedEvents = true
      @todoController.renderTo( $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom." )
      expect( @todoController.todoClickArguments ).toBeUndefined()

    it "auto detaches events if they don't match the selector anymore"

    it "re-attaches events when the model changes (after the re-render)", ->
      @todoController.renderTo( $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom 1." )
      expect( @todoController.todoClickArguments ).toMatchArray( ["Boom 1.", $$( "#test p" )[0], @todoController.views[0]] )
      @todo.set( "num", "two" )
      $$( "#test p" ).fireEvent( "click", "Boom 2." )
      expect( @todoController.todoClickArguments ).toMatchArray( ["Boom 2.", $$( "#test p" )[0], @todoController.views[0]] )
