describe "Model", ->
  beforeEach resetRickshaw

  describe "creating", ->
    beforeEach ->
      @Todo = new Model()

    it "creates an instance", ->
      todo = new @Todo()
      expect( instanceOf( todo, @Todo ) ).to.be( true )

  describe "subclassing", ->
    it "works", ->
      Todo = new Model {
        isTodo: true
        getThis: -> this
      }

      MegaTodo = new Model {
        Extends: Todo
        isTodo: false
        isMegaTodo: true
      }

      megaTodo = new MegaTodo()
      expect( megaTodo.data ).to.eql( {} )
      expect( megaTodo.isTodo ).to.be( false )
      expect( megaTodo.isMegaTodo ).to.be( true )
      expect( megaTodo.getThis() ).to.be( megaTodo )

  describe "#get()", ->
    beforeEach ->
      @Todo = new Model {
        Defaults: { rad: true, neat: -> "yes" }
        getTime: -> @data.time.capitalize()
        getCamelcaseText: -> this.get( "text" ).forceCamelCase()
      }
      @todo = new @Todo {
        text: "Read a book"
        done: false
        time: "today"
      }

    it "gets properties", ->
      expect( @todo.get( "text" ) ).to.eql( "Read a book" )
      expect( @todo.get( "done" ) ).to.be( false )

    it "gets many properties at once", ->
      expect( @todo.get( "text", "done" ) ).to.eql( { text: "Read a book", done: false } )
      expect( @todo.get([ "text", "done" ]) ).to.eql( { text: "Read a book", done: false } )

    it "can have default values", ->
      expect( @todo.get( "rad" ) ).to.be( true )
      expect( @todo.get( "neat" ) ).to.eql( "yes" ) # as functions

    it "can have custom getters", ->
      expect( @todo.get( "time" ) ).to.eql( "Today" )
      expect( @todo.get( "camelcaseText" ) ).to.eql( "ReadABook" )

  describe "#set()", ->
    beforeEach ->
      @Todo = new Model {
        Defaults: { done: false }
        setTitle: (title) -> return title.capitalize()
        setCoolCat: (value) -> return "#{value}"
      }
      @todo = new @Todo()

    it "sets properties", ->
      expect( @todo.set( "stuff", "cool" ) ).to.eql( @todo )
      expect( @todo.get( "stuff" ) ).to.eql( "cool" )

    it "uses custom setters", ->
      expect( @todo.set( "title", "work" ) ).to.eql( @todo )
      expect( @todo.get( "title" ) ).to.eql( "Work" )

    it "sets many properties at once", ->
      expect( @todo.set({ a: 1, b: 2 }) ).to.eql( @todo )
      expect( @todo.get( "a" ) ).to.eql( 1 )
      expect( @todo.get( "b" ) ).to.eql( 2 )

    it "tracks dirty states of basic primitives", ->
      expect( @todo.dirtyProperties ).to.eql( [] )
      @todo.set "done", false
      expect( @todo.dirtyProperties ).to.eql( [] )
      @todo.set "done", true
      expect( @todo.dirtyProperties ).to.eql( ["done"] )
      @todo.set "title", "work"
      expect( @todo.dirtyProperties ).to.eql( ["done", "title"] )

    it "tracks dirty states with custom setters", ->
      @todo = new @Todo({ title: "Work" })
      @todo.set "title", "work"
      expect( @todo.dirtyProperties ).to.eql( [] )
      @todo.set "title", "play"
      expect( @todo.dirtyProperties ).to.eql( ["title"] )

    it "tracks dirty states of arrays ", ->
      @todo = new @Todo({ blob: [1, 2] })
      @todo.set "blob", [1, 2]
      expect( @todo.dirtyProperties ).to.eql( [] )
      @todo.set "blob", [1, 3]
      expect( @todo.dirtyProperties ).to.eql( ["blob"] )
      # And back
      @todo.set "blob", [1, 2]
      expect( @todo.dirtyProperties ).to.eql( [] )

    it "tracks dirty states of objects", ->
      @todo = new @Todo({ blob: {a: [1, 2]} })
      @todo.set "blob", {a: [1, 2]}
      expect( @todo.dirtyProperties ).to.eql( [] )
      @todo.set "blob", {a: [1, 3]}
      expect( @todo.dirtyProperties ).to.eql( ["blob"] )
      # And back
      @todo.set "blob", {a: [1, 2]}
      expect( @todo.dirtyProperties ).to.eql( [] )

    it "fires change events", ->
      eventFired = false
      propertyEventFired = false
      changeEventFired = false
      changedEvent = false

      @Todo = new Model {
        onBlobChange: ->
          propertyEventFired = true
          @propertyEventFired = "yep"
        onChange: ->
          changeEventFired = true
          @changeEventFired = "yep"
      }
      @todo = new @Todo { blob: "foo" }
      @todo.addEvent "blobChange", ->
        eventFired = true
        this.eventFired = "yep"
      @todo.addEvent "change", -> changedEvent = Array.from( arguments )

      @todo.set "blob", "foo"
      expect( eventFired ).to.be( false )
      expect( propertyEventFired ).to.be( false )
      expect( changeEventFired  ).to.be( false )
      expect( changedEvent ).to.be( false )

      @todo.set { blob: "bar", other: "rad" }
      expect( eventFired ).to.be( true )
      expect( propertyEventFired ).to.be( true )
      expect( changeEventFired ).to.be( true )
      expect( changedEvent ).to.eql( [@todo, ["blob", "other"]] )
      expect( @todo.eventFired ).to.eql( "yep" )
      expect( @todo.propertyEventFired ).to.eql( "yep" )
      expect( @todo.changeEventFired ).to.eql( "yep" )

  describe "#toggle()", ->
    beforeEach ->
      @Todo = new Model {
        getDone: -> @data.done == "true"
        setDone: (value) -> return "#{value}"
      }
      @todo = new @Todo()

    it "toggles the value and uses custom getters / setters", ->
      expect( @todo.toggle "done" ).to.be( @todo )
      expect( @todo.get "done" ).to.be( true )
      expect( @todo.data.done ).to.eql( "true" )

    it "marks value as dirty", ->
      @todo.toggle "done"
      expect( @todo.dirtyProperties ).to.eql( ["done"] )

    it "fires change events", ->
      changeEvent = new EventCapture @todo, "change"
      @todo.toggle "done"
      expect( changeEvent.timesFired ).to.be( 1 )
      expect( changeEvent.arguments ).to.matchArray( [@todo, ["done"]] )
