require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Rickshaw.Controller", ->
  beforeEach setupCustomMatchers

  describe "creating", ->
    beforeEach ->
      @Todo = new Rickshaw.Model()
      @todo = new @Todo {num: "one"}
      @TodoController = new Rickshaw.Controller({
        Template: "todo"
      })

    it "has an associated model", ->
      todoController = new @TodoController( @todo )
      expect( todoController.model ).toBe( @todo )

    it "can be created without a model", ->
      todoController = new @TodoController()
      expect( todoController.model ).toBeNull()
      # and add model later
      expect( todoController.setModel( @todo ) ).toBe( todoController )
      expect( todoController.model ).toBe( @todo )

  describe "model events", ->
    beforeEach ->
      @Todo = new Rickshaw.Model()
      @todo = new @Todo {num: "one"}
      @TodoController = new Rickshaw.Controller({
        Template: "todo"
      })
      @todoController = new @TodoController()
      # TODO: This is so awful. God.
      spyOn( @todoController, "_modelChanged" ).andCallThrough()
      @todoController.setModel( @todo )
      @todoController._modelChanged.reset()

    it "binds events to the model", ->
      @todo.set neat: true, rad: true
      expect( @todoController._modelChanged.callCount ).toBe( 1 )
      expect( @todoController._modelChanged.argsForCall[0] ).toEqualArray( [@todo, ["neat", "rad"]] )

    it "removes the events when setting a new model", ->
      @todo2 = new @Todo()
      @todoController.setModel( @todo2 )
      @todo.set sweet: true
      expect( @todoController._modelChanged ).not.toHaveBeenCalled()

  describe "dever to model", ->
    beforeEach ->
      @Todo = new Rickshaw.Model()
      @todo = new @Todo {num: "one"}
      @TodoController = new Rickshaw.Controller({
        Template: "todo"
      })
      @todoController = new @TodoController()

    it "should be able to defer methods to the model", ->
      

  describe "rendering", ->
    beforeEach ->
      @Todo = new Rickshaw.Model()
      @todo = new @Todo {text: "do stuff"}
      @TodoController = new Rickshaw.Controller({
        Template: "todo"
        klass: -> "neato"
        text: -> "TODO: #{@model.get('text')}"
        Events:
          p:
            click: ->
              @todoClickArguments = Array.from arguments
      })
      rickshawTemplate "todo", "
        <p class='{{klass}}'>{{text}}</p>
      "

    it "renders later without element", ->
      todoController = new @TodoController( @todo )
      expect( $( "test" ).innerHTML ).toEqual( "" )
      expect( todoController.render() ).toBe( false )
      todoController.renderTo( $( "test" ) )
      expect( todoController.render() ).toBe( true )
      expect( todoController.rendered ).toBe( true )
      expect( $( "test" ).innerHTML ).toMatch( /<p class="neato">TODO: do stuff<\/p>/ )

    it "renders on create with element", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      expect( $( "test" ).innerHTML ).toMatch( /<p class="neato">TODO: do stuff<\/p>/ )
      expect( todoController.rendered ).toBe( true )

    it "renders HTML to multiple locations simultaneously", ->
      todoController = new @TodoController( @todo )
      todoController.renderTo( $( "test" ) )
      todoController.renderTo( $( "test" ) )
      expect( $( "test" ).innerHTML ).toMatch( /(<p class="neato">TODO: do stuff<\/p>.+){2}/ )
      expect( todoController.rendered ).toBe( true )

    it "attaches element events", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      $$( "#test p" ).fireEvent( "click", "Boom." )
      expect( todoController.todoClickArguments ).toEqualArray( ["Boom.", $$( "#test p" )[0]] )

    it "auto detaches events if they don't match the selector anymore", ->
      # TODO

    it "re-renders when the model changes and re-attaches events", ->
      todoController = new @TodoController( @todo, $( "test" ) )
      @todo.set( "text", "Neato." )
      expect( $$( "#test p" )[0].innerHTML ).toEqual( "TODO: Neato." )
      expect( todoController.rendered ).toBe( true )
