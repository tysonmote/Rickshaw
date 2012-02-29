require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "List", ->
  beforeEach setupCustomMatchers
  beforeEach ->
    @Todo = Todo = new Model()
    @MegaTodo = MegaTodo = new Model()
    @TodoList = new List {
      ModelClass: Todo
    }
    @CombinedTodoList = new List {
      ModelClass: (data) ->
        if data.isMegaTodo then MegaTodo else Todo
    }
    @todo1 = new @Todo {num: "one"}
    @todo2 = new @Todo {num: "two"}
    @megaTodo1 = new @Todo {num: "three"}
    @megaTodo2 = new @Todo {num: "four"}

  describe "creating", ->
    it "creates an empty Array-like list", ->
      todoList = new @TodoList()
      expect( todoList ).toMatchArray( [] )
      expect( todoList.length ).toBe( 0 )
      expect( typeOf( todoList ) ).toBe( "array" )

    it "creates pre-filled lists", ->
      todoList = new @TodoList @todo1, @todo2
      expect( todoList ).toMatchArray( [@todo1, @todo2] )

  # Adding
  # ------

  describe "#push", ->
    beforeEach ->
      @todoList = new @TodoList @todo1

    it "adds objects", ->
      expect( @todoList.push( @todo2 ) ).toEqual( 2 )
      expect( @todoList ).toMatchArray( [@todo1, @todo2] )
      expect( @todoList.push( @todo2, @todo1 ) ).toEqual( 4 )
      expect( @todoList ).toMatchArray( [@todo1, @todo2, @todo2, @todo1] )

    it "fires onAdd events", ->
      addEvent = new EventCapture @todoList, "add"
      @todoList.push @todo2
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@todo2], "end"] )
      expect( addEvent.timesFired ).toBe( 1 )

  describe "#unshift", ->
    beforeEach ->
      @todoList = new @TodoList @todo1

    it "adds objects", ->
      expect( @todoList.unshift( @todo2 ) ).toEqual( 2 )
      expect( @todoList ).toMatchArray( [@todo2, @todo1] )
      expect( @todoList.unshift( @todo2, @todo1 ) ).toEqual( 4 )
      expect( @todoList ).toMatchArray( [@todo2, @todo1, @todo2, @todo1] )

    it "fires onAdd events", ->
      addEvent = new EventCapture @todoList, "add"
      @todoList.unshift @todo2
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@todo2], "beginning"] )
      expect( addEvent.timesFired ).toBe( 1 )

  describe "#include", ->
    beforeEach ->
      @todoList = new @TodoList @todo1

    it "adds objects", ->
      expect( @todoList.include( @todo2 ) ).toEqual( @todoList )
      expect( @todoList ).toMatchArray( [@todo1, @todo2] )
      # Doesn't add duplicates
      expect( @todoList.include( @todo2 ) ).toEqual( @todoList )
      expect( @todoList ).toMatchArray( [@todo1, @todo2] )

    it "fires onAdd events", ->
      addEvent = new EventCapture @todoList, "add"
      @todoList.include @todo2
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@todo2], "end"] )
      expect( addEvent.timesFired ).toBe( 1 )
      # Doesn't fire if model is already in array
      addEvent.reset()
      @todoList.include @todo2
      expect( addEvent.arguments ).toBeNull()
      expect( addEvent.timesFired ).toBe( 0 )

  describe "#combine", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1

    it "adds objects", ->
      expect( @todoList.combine( [@todo2, @megaTodo1] ) ).toEqual( @todoList )
      expect( @todoList ).toMatchArray( [@todo1, @todo2, @megaTodo1] )
      # Doesn't add duplicates
      expect( @todoList.combine( [@todo2, @megaTodo1, @megaTodo2] ) ).toEqual( @todoList )
      expect( @todoList ).toMatchArray( [@todo1, @todo2, @megaTodo1, @megaTodo2] )

    it "fires onAdd events", ->
      addEvent = new EventCapture @todoList, "add"
      @todoList.combine [@todo2, @megaTodo1]
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@todo2, @megaTodo1], "end"] )
      expect( addEvent.timesFired ).toBe( 1 )
      # Fires if only one model isn't in array yet
      addEvent.reset()
      @todoList.combine [@megaTodo1, @megaTodo2]
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@megaTodo2], "end"] )
      expect( addEvent.timesFired ).toBe( 1 )
      # Doesn't fire if all models are already in array
      addEvent.reset()
      @todoList.combine [@todo2]
      expect( addEvent.arguments ).toBeNull()
      expect( addEvent.timesFired ).toBe( 0 )

  describe "adding objects", ->
    it "creates new model instances given a model class", ->
      @todoList = new @TodoList()
      expect( @todoList.push( {}, {} ) ).toBe( 2 )
      expect( @todoList[0] ).toBeInstanceOf( @Todo )
      expect( @todoList[1] ).toBeInstanceOf( @Todo )

    it "creates new model instances given a function", ->
      @combinedTodoList = new @CombinedTodoList()
      expect( @combinedTodoList.push( {isMegaTodo: true }, {isMegaTodo: false} ) ).toBe( 2 )
      expect( @combinedTodoList[0] ).toBeInstanceOf( @MegaTodo )
      expect( @combinedTodoList[1] ).toBeInstanceOf( @Todo )

  # Removing
  # --------

  describe "#pop", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2, @megaTodo1, @megaTodo2

    it "removes objects", ->
      expect( @todoList.pop() ).toBe( @megaTodo2 )
      expect( @todoList ).toMatchArray( [@todo1, @todo2, @megaTodo1] )

    it "fires onRemoveEvents", ->
      removeEvent = new EventCapture @todoList, "remove"
      @todoList.pop()
      expect( removeEvent.arguments ).toMatchArray( [@todoList, [@megaTodo2], "end"] )
      expect( removeEvent.timesFired ).toBe( 1 )

  describe "#shift", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2, @megaTodo1, @megaTodo2

    it "removes objects", ->
      expect( @todoList.shift() ).toBe( @todo1 )
      expect( @todoList ).toMatchArray( [@todo2, @megaTodo1, @megaTodo2] )

    it "fires onRemoveEvents", ->
      removeEvent = new EventCapture @todoList, "remove"
      @todoList.shift()
      expect( removeEvent.arguments ).toMatchArray( [@todoList, [@todo1], "beginning"] )
      expect( removeEvent.timesFired ).toBe( 1 )

  describe "#erase", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2, @megaTodo1, @megaTodo2, @todo2

    it "removes objects", ->
      expect( @todoList.erase( @todo2 ) ).toBe( @todoList )
      expect( @todoList ).toMatchArray( [@todo1, @megaTodo1, @megaTodo2] )

    it "can't remove non-model objects yet", ->
      # TODO: Figure out what's up with Jasmine's toThrow() matcher.
      thrownError = null
      try
        @todoList.erase( {cool: true} )
      catch error
        thrownError = error
      expect( thrownError.message ).toEqual( "Can't erase non-model objects yet." )

    it "fires onRemoveEvents", ->
      removeEvent = new EventCapture @todoList, "remove"
      @todoList.erase( @todo2 )
      expect( removeEvent.arguments ).toMatchArray( [@todoList, [@todo2], [4, 1]] )
      expect( removeEvent.timesFired ).toBe( 1 )

  describe "empty", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2

    it "removes all models", ->
      expect( @todoList.empty() ).toBe( @todoList )
      expect( @todoList ).toMatchArray( [] )

    it "fires an onRemove event", ->
      removeEvent = new EventCapture @todoList, "remove"
      @todoList.empty()
      expect( removeEvent.arguments ).toMatchArray( [@todoList, [@todo1, @todo2], "all"] )
      expect( removeEvent.timesFired ).toBe( 1 )
      # Doesn't fire event if there's nothing to empty
      removeEvent.reset()
      @todoList.empty()
      expect( removeEvent.arguments ).toBeNull()
      expect( removeEvent.timesFired ).toBe( 0 )

  describe "splice", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2

    it "does nothing", ->
      expect( @todoList.splice( 1, 0 ) ).toMatchArray( [] )
      expect( @todoList ).toMatchArray( [@todo1, @todo2] )

    it "removes a model", ->
      expect( @todoList.splice( 1, 1 ) ).toMatchArray( [@todo2] )
      expect( @todoList ).toMatchArray( [@todo1] )

    it "removes multiple models", ->
      @todoList.push( @megaTodo1, @megaTodo2 )
      expect( @todoList.splice( 1, 2 ) ).toMatchArray( [@todo2, @megaTodo1] )
      expect( @todoList ).toMatchArray( [@todo1, @megaTodo2] )

    it "removes models", ->
      expect( @todoList.splice( 1, 2 ) ).toMatchArray( [@todo2] )

    it "adds a model", ->
      expect( @todoList.splice( 1, 0, @megaTodo1 ) ).toMatchArray( [] )
      expect( @todoList ).toMatchArray( [@todo1, @megaTodo1, @todo2] )

    it "adds multtiple models", ->
      expect( @todoList.splice( 1, 0, @megaTodo1, @megaTodo2 ) ).toMatchArray( [] )
      expect( @todoList ).toMatchArray( [@todo1, @megaTodo1, @megaTodo2, @todo2] )

    it "removes and adds models", ->
      @todoList.push( @megaTodo1 )
      expect( @todoList.splice( 1, 1, @todo1 ) ).toMatchArray( [@todo2] )
      expect( @todoList ).toMatchArray( [@todo1, @todo1, @megaTodo1] )

    it "fires remove events", ->
      removeEvent = new EventCapture @todoList, "remove"
      @todoList.push( @megaTodo1, @megaTodo2 )
      @todoList.splice( 1, 2 )
      expect( removeEvent.arguments ).toMatchArray( [@todoList, [@todo2, @megaTodo1], 1] )
      expect( removeEvent.timesFired ).toBe( 1 )

    it "fires add events", ->
      addEvent = new EventCapture @todoList, "add"
      @todoList.splice( 1, 0, @megaTodo1, @megaTodo2 )
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@megaTodo1, @megaTodo2], 1] )
      expect( addEvent.timesFired ).toBe( 1 )

    it "fires both events", ->
      # TODO spec order of event firing: "remove" then "add"
      removeEvent = new EventCapture @todoList, "remove"
      addEvent = new EventCapture @todoList, "add"
      @todoList.push( @megaTodo1, @megaTodo2 )
      @todoList.splice( 1, 2, @todo1 )
      expect( removeEvent.arguments ).toMatchArray( [@todoList, [@todo2, @megaTodo1], 1] )
      expect( addEvent.arguments ).toMatchArray( [@todoList, [@todo1], 1] )

  # Nested events
  # -------------

  describe "model events", ->
    beforeEach ->
      @todoList = new @TodoList @todo1, @todo2

    it "bubbles change events", ->
      changeEvent = new EventCapture @todoList, "change"
      @todo1.set "rad", true
      expect( changeEvent.arguments ).toMatchArray( [@todoList, @todo1, ["rad"]] )
      expect( changeEvent.timesFired ).toBe( 1 )

    it "stops bubbling events when removed", ->
      changeEvent = new EventCapture @todoList, "change"
      @todoList.erase @todo1
      @todo1.set "rad", true
      expect( changeEvent.timesFired ).toBe( 0 )

    it "fires events only once when model is in list multiple times", ->
      changeEvent = new EventCapture @todoList, "change"
      @todoList.push @todo1
      @todo1.set "rad", true
      expect( changeEvent.timesFired ).toBe( 1 )

  # Sorting
  # -------

  describe "#sort", ->
    beforeEach ->
      @todoList = new @TodoList( @todo1, @todo2, @megaTodo1 )
      @todo1.set( "rad", 1 )
      @todo2.set( "rad", 0 )
      @megaTodo1.set( "rad", 2 )

    it "sorts with a function", ->
      result = @todoList.sort (a, b) ->
        Array._compare( a.get( "rad" ), b.get( "rad" ) )
      expect( result ).toBe( @todoList )
      expect( @todoList ).toMatchArray( [@todo2, @todo1, @megaTodo1] )

    it "sorts ascending with a model property", ->
      expect( @todoList.sort( "rad", "ascending" ) ).toBe( @todoList )
      expect( @todoList ).toMatchArray( [@todo2, @todo1, @megaTodo1] )

    it "sorts descending with a model property", ->
      expect( @todoList.sort( "rad", "descending" ) ).toBe( @todoList )
      expect( @todoList ).toMatchArray( [@megaTodo1, @todo1, @todo2] )

    it "fires the sort event", ->
      sortEvent = new EventCapture @todoList, "sort"
      @todoList.sort( "rad" )
      expect( sortEvent.timesFired ).toBe( 1 )
      expect( sortEvent.arguments ).toMatchArray( [@todoList] )

    it "doesn't fire the sort event if the order didn't change", ->
      sortEvent = new EventCapture @todoList, "sort"
      @todoList.sort( "rad" )
      @todoList.sort( "rad" )
      expect( sortEvent.timesFired ).toBe( 1 )

  describe "#reverse", ->
    beforeEach ->
      @todoList = new @TodoList( @todo1, @todo2, @megaTodo1 )

    it "reverses the contents", ->
      expect( @todoList.reverse() ).toBe( @todoList )
      expect( @todoList ).toMatchArray( [@megaTodo1, @todo2, @todo1] )

    it "fires the sort event", ->
      sortEvent = new EventCapture @todoList, "sort"
      @todoList.reverse()
      expect( sortEvent.timesFired ).toBe( 1 )
      expect( sortEvent.arguments ).toMatchArray( [@todoList, "reverse"] )

    it "doesn't fire anything for lists with 0 or 1 elements", ->
      @todoList.pop()
      @todoList.pop() # 1 item left
      sortEvent = new EventCapture @todoList, "sort"
      expect( @todoList.reverse() ).toBe( @todoList )
      @todoList.pop()
      expect( @todoList.reverse() ).toBe( @todoList )
      expect( sortEvent.timesFired ).toBe( 0 )
