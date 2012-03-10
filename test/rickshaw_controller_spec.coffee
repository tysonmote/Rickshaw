describe "Controller", ->
  beforeEach resetRickshaw

  describe "creating", ->
    beforeEach Fixtures.simpleTodoController

    it "has an associated model", ->
      expect( @todoController.model ).to.be( @todo )

    it "can be created without a model", ->
      todoController = new @TodoController()
      expect( todoController.model ).to.be( null )
      # and add model later
      expect( todoController.setModel( @todo ) ).to.be( todoController )
      expect( todoController.model ).to.be( @todo )

    it "is not rendered anywhere", ->
      expect( @todoController.rendered ).to.be( false )
      expect( $$( "p.todo" ) ).to.be.empty()

  describe "preattached events", ->
    it "attaches on initialize", ->
      MyController = new Controller( onCoolEvent: -> )
      controller = new MyController()
      event = new EventCapture controller, "coolEvent"
      controller.fireEvent( "coolEvent", [1, "cool"] )
      expect( event.timesFired ).to.be( 1 )
      expect( event.arguments ).to.matchArray( [1, "cool"] )

  describe "model events", ->
    beforeEach Fixtures.simpleTodoController
    beforeEach ->
      @todoControllerModelChangedMethod = sinon.spy( @todoController, "_modelChanged" )
      @todoController.setModel( @todo )
      @todoControllerModelChangedMethod.reset()

    afterEach ->
      @todoControllerModelChangedMethod.restore()

    it "binds events to the model", ->
      @todo.set neat: true, rad: true
      expect( @todoControllerModelChangedMethod ).to.have.been.calledOnce()
      expect( @todoControllerModelChangedMethod ).to.have.been.calledWith( @todo, ["neat", "rad"] )

    it "removes the events when setting a new model", ->
      @todo2 = new @Todo()
      @todoController.setModel( @todo2 )
      @todo.set sweet: true
      expect( @todoControllerModelChangedMethod ).not.to.have.been.called()

  describe "defer to model", ->
    beforeEach Fixtures.simpleTodoControllerWithDefer

    it "should be able to defer methods to the model", ->
      expect( @todoController.num() ).to.eql( "one" )

  describe "rendering", ->
    beforeEach Fixtures.simpleTodoControllerWithClickEvent

    it "doesn't render without a destination", ->
      expect( @todoController.render() ).to.be( false )
      expect( $$( "p.todo" ) ).to.be.empty()

    it "renders to a destination (bottom by default)", ->
      $( "test" ).set( "html", "<div id='wrap'><span>1</span></div>")
      expect( @todoController.renderTo( $( "wrap" ) ) ).to.be( true )
      expect( @todoController.rendered ).to.be( true )
      expect( $( "test" ).innerHTML ).to.match( /<div id="wrap"><span>\d+<\/span><script id="metamorph-\d+-start" type="text\/x-placeholder"><\/script><p class="todo neato">one<\/p><script id="metamorph-\d+-end" type="text\/x-placeholder"><\/script><\/div>/ )

    it "renders to the top of a destination", ->
      $( "test" ).set( "html", "<div id='wrap'><span>1</span></div>")
      expect( @todoController.renderTo( $( "wrap" ), "top" ) ).to.be( true )
      expect( @todoController.rendered ).to.be( true )
      expect( $( "test" ).innerHTML ).to.match( /<div id="wrap"><script id="metamorph-\d+-start" type="text\/x-placeholder"><\/script><p class="todo neato">one<\/p><script id="metamorph-\d+-end" type="text\/x-placeholder"><\/script><span>\d+<\/span><\/div>/ )

    it "renders on creation when passed an element", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      expect( $( "test" ).innerHTML ).to.match( /<p class="todo neato">one<\/p>/ )
      expect( todoController.rendered ).to.be( true )

    it "renders HTML to multiple locations simultaneously", ->
      @todoController.renderTo( $( "test" ) )
      @todoController.renderTo( $( "test" ) )
      expect( $( "test" ).innerHTML ).to.match( /(<p class="todo neato">one<\/p>.+){2}/ )
      expect( @todoController.rendered ).to.be( true )

    it "re-renders when the model changes", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      @todo.set( "num", "two" )
      expect( $$( "#test p" )[0].innerHTML ).to.eql( "two" )
      expect( todoController.rendered ).to.be( true )

  describe "events", ->
    beforeEach Fixtures.simpleTodoControllerWithClickEvent

    it "attaches element events on render", ->
      @todoController.renderTo( $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom." )
      expect( @todoController.todoClickArguments ).to.matchArray( ["Boom.", $$( "#test p" )[0], @todoController.views[0]] )

    it "doesn't attach element events if `_useRelayedEvents` is true", ->
      throw new Error "TODO: fix"
      @todoController._useRelayedEvents = true
      @todoController.renderTo( $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom." )
      expect( @todoController.todoClickArguments ).to.be( undefined )

    it "auto detaches events if they don't match the selector anymore"

    it "re-attaches events when the model changes (after the re-render)", ->
      @todoController.renderTo( $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom 1." )
      expect( @todoController.todoClickArguments ).to.matchArray( ["Boom 1.", $$( "#test p" )[0], @todoController.views[0]] )
      @todo.set( "num", "two" )
      $$( "#test p" ).fireEvent( "click", "Boom 2." )
      expect( @todoController.todoClickArguments ).to.matchArray( ["Boom 2.", $$( "#test p" )[0], @todoController.views[0]] )
