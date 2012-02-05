require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Rickshaw.Model", ->
  describe "creating", ->
    beforeEach ->
      @Todo = new Rickshaw.Model()

    it "creates an instance", ->
      todo = new @Todo()
      expect( instanceOf( todo, @Todo ) ).toBe( true )

  describe "subclassing", ->
    it "works", ->
      Todo = new Rickshaw.Model {
        isTodo: true
        getThis: -> this
      }

      MegaTodo = new Rickshaw.Model {
        Extends: Todo
        isTodo: false
        isMegaTodo: true
      }

      megaTodo = new MegaTodo()
      expect( megaTodo.data ).toEqual( {} )
      expect( megaTodo.isTodo ).toBe( false )
      expect( megaTodo.isMegaTodo ).toBe( true )
      expect( megaTodo.getThis() ).toBe( megaTodo )

  describe "#get()", ->
    beforeEach ->
      @Todo = new Rickshaw.Model {
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
      expect( @todo.get( "text" ) ).toEqual( "Read a book" )
      expect( @todo.get( "done" ) ).toEqual( false )

    it "gets many properties at once", ->
      expect( @todo.get( "text", "done" ) ).toEqual( { text: "Read a book", done: false } )
      expect( @todo.get([ "text", "done" ]) ).toEqual( { text: "Read a book", done: false } )

    it "can have default values", ->
      expect( @todo.get( "rad" ) ).toBe( true )
      expect( @todo.get( "neat" ) ).toEqual( "yes" ) # as functions

    it "can have custom getters", ->
      expect( @todo.get( "time" ) ).toEqual( "Today" )
      expect( @todo.get( "camelcaseText" ) ).toEqual( "ReadABook" )

  describe "#set()", ->
    beforeEach ->
      @Todo = new Rickshaw.Model {
        Defaults: { done: false }
        setTitle: (title) -> return title.capitalize()
        setCoolCat: (value) -> return "#{value}"
      }
      @todo = new @Todo()

    it "sets properties", ->
      expect( @todo.set( "stuff", "cool" ) ).toEqual( @todo )
      expect( @todo.get( "stuff" ) ).toEqual( "cool" )

    it "uses custom setters", ->
      expect( @todo.set( "title", "work" ) ).toEqual( @todo )
      expect( @todo.get( "title" ) ).toEqual( "Work" )

    it "sets many properties at once", ->
      expect( @todo.set({ a: 1, b: 2 }) ).toEqual( @todo )
      expect( @todo.get( "a" ) ).toEqual( 1 )
      expect( @todo.get( "b" ) ).toEqual( 2 )

    it "tracks dirty states of basic primitives", ->
      expect( @todo.dirtyProperties ).toEqual( [] )
      @todo.set "done", false
      expect( @todo.isDirty() ).toBe( false )
      expect( @todo.dirtyProperties ).toEqual( [] )
      @todo.set "done", true
      expect( @todo.isDirty() ).toBe( true )
      expect( @todo.dirtyProperties ).toEqual( ["done"] )
      @todo.set "title", "work"
      expect( @todo.isDirty() ).toBe( true )
      expect( @todo.dirtyProperties ).toEqual( ["done", "title"] )

    it "tracks dirty states with custom setters", ->
      @todo = new @Todo({ title: "Work" })
      @todo.set "title", "work"
      expect( @todo.isDirty() ).toBe( false )
      expect( @todo.dirtyProperties ).toEqual( [] )
      @todo.set "title", "play"
      expect( @todo.isDirty() ).toBe( true )
      expect( @todo.dirtyProperties ).toEqual( ["title"] )

    it "tracks dirty states of arrays ", ->
      @todo = new @Todo({ blob: [1, 2] })
      @todo.set "blob", [1, 2]
      expect( @todo.dirtyProperties ).toEqual( [] )
      @todo.set "blob", [1, 3]
      expect( @todo.dirtyProperties ).toEqual( ["blob"] )
      # And back
      @todo.set "blob", [1, 2]
      expect( @todo.dirtyProperties ).toEqual( [] )

    it "tracks dirty states of objects", ->
      @todo = new @Todo({ blob: {a: [1, 2]} })
      @todo.set "blob", {a: [1, 2]}
      expect( @todo.dirtyProperties ).toEqual( [] )
      @todo.set "blob", {a: [1, 3]}
      expect( @todo.dirtyProperties ).toEqual( ["blob"] )
      # And back
      @todo.set "blob", {a: [1, 2]}
      expect( @todo.dirtyProperties ).toEqual( [] )

    it "fires change events", ->
      eventFired = false
      propertyEventFired = false
      changedEvent = false

      @Todo = new Rickshaw.Model {
        onBlobChange: ->
          propertyEventFired = true
          @propertyEventFired = "yep"
      }
      @todo = new @Todo { blob: "foo" }
      @todo.addEvent "blobChange", ->
        eventFired = true
        this.eventFired = "yep"
      @todo.addEvent "change", -> changedEvent = Array.from( arguments )

      @todo.set "blob", "foo"
      expect( eventFired ).toBe( false )
      expect( propertyEventFired ).toBe( false )
      expect( changedEvent ).toBe( false )

      @todo.set { blob: "bar", other: "rad" }
      expect( eventFired ).toBe( true )
      expect( propertyEventFired ).toBe( true )
      expect( changedEvent ).toEqual( [@todo, ["blob", "other"]] )
      expect( @todo.eventFired ).toEqual( "yep" )
      expect( @todo.propertyEventFired ).toEqual( "yep" )

    describe "#toggle()", ->
      beforeEach setupCustomMatchers
      beforeEach ->
        @Todo = new Rickshaw.Model {
          getDone: -> @data.done == "true"
          setDone: (value) -> return "#{value}"
        }
        @todo = new @Todo()

      it "toggles the value and uses custom getters / setters", ->
        expect( @todo.toggle "done" ).toBe( @todo )
        expect( @todo.get "done" ).toBe( true )
        expect( @todo.data.done ).toEqual( "true" )

      it "marks value as dirty", ->
        @todo.toggle "done"
        expect( @todo.dirtyProperties ).toEqual( ["done"] )

      it "fires change events", ->
        changeEvent = new EventCapture @todo, "change"
        @todo.toggle "done"
        expect( changeEvent.timesFired ).toBe( 1 )
        expect( changeEvent.arguments ).toEqualArray( [@todo, ["done"]] )
