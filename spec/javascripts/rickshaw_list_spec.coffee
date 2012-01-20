require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Rickshaw.List", ->
  beforeEach setupCustomMatchers
  beforeEach ->
    @Todo = Todo = new Rickshaw.Model()
    @MegaTodo = MegaTodo = new Rickshaw.Model()
    @TodoList = new Rickshaw.List {
      modelClass: Todo
    }
    @CombinedTodoList = new Rickshaw.List {
      modelClass: (data) ->
        if data.isMegaTodo then MegaTodo else Todo
    }
    @todo1 = new @Todo {num: "one"}
    @todo2 = new @Todo {num: "two"}
    @megaTodo1 = new @Todo {num: "three"}
    @megaTodo2 = new @Todo {num: "four"}

  describe "creating", ->
    it "creates an empty Array-like list", ->
      todoList = new @TodoList()
      expect( todoList ).toEqualArray []
      expect( todoList.length ).toBe 0
      expect( typeOf( todoList ) ).toBe "array"

    it "creates pre-filled lists", ->
      todoList = new @TodoList @todo1, @todo2
      expect( todoList ).toEqualArray [@todo1, @todo2]

  # Adding
  # ------

  describe "#push", ->
    beforeEach ->
      @todoList = new @TodoList @todo1

    it "adds objects", ->
      expect( @todoList.push( @todo2 ) ).toEqual 2
      expect( @todoList ).toEqualArray [@todo1, @todo2]
      expect( @todoList.push( @todo2, @todo1 ) ).toEqual( 4 )
      expect( @todoList ).toEqualArray [@todo1, @todo2, @todo2, @todo1]

    it "fires onAdd events", ->
      eventArgs = null
      @todoList.addEvent "add", -> eventArgs = Array.from( arguments )
      @todoList.push @todo2
      expect( eventArgs ).toEqualArray [@todoList, [@todo2], "end"]

  describe "#unshift", ->
    beforeEach ->
      @todoList = new @TodoList @todo1

    it "adds objects", ->
      expect( @todoList.unshift( @todo2 ) ).toEqual 2
      expect( @todoList ).toEqualArray [@todo2, @todo1]
      expect( @todoList.unshift( @todo2, @todo1 ) ).toEqual( 4 )
      expect( @todoList ).toEqualArray [@todo2, @todo1, @todo2, @todo1]

    it "fires onAdd events", ->
      eventArgs = null
      @todoList.addEvent "add", -> eventArgs = Array.from( arguments )
      @todoList.unshift @todo2
      expect( eventArgs ).toEqualArray [@todoList, [@todo2], "beginning"]

  describe "#include", ->
    beforeEach ->
      @todoList = new @TodoList @todo1

    it "adds objects", ->
      expect( @todoList.include( @todo2 ) ).toEqual @todoList
      expect( @todoList ).toEqualArray [@todo1, @todo2]
      # Doesn't add duplicates
      expect( @todoList.include( @todo2 ) ).toEqual @todoList
      expect( @todoList ).toEqualArray [@todo1, @todo2]

    it "fires onAdd events", ->
      eventArgs = null
      @todoList.addEvent "add", -> eventArgs = Array.from( arguments )
      @todoList.include @todo2
      expect( eventArgs ).toEqualArray [@todoList, [@todo2], "beginning"]
      # Doesn't fire if model is already in array
      eventArgs = null
      @todoList.include @todo2
      expect( eventArgs ).toBeNull()

  describe "#combine", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1

    it "adds objects", ->
      expect( @todoList.combine( [@todo2, @megaTodo1] ) ).toEqual @todoList
      expect( @todoList ).toEqualArray [@todo1, @todo2, @megaTodo1]
      # Doesn't add duplicates
      expect( @todoList.combine( [@todo2, @megaTodo1, @megaTodo2] ) ).toEqual @todoList
      expect( @todoList ).toEqualArray [@todo1, @todo2, @megaTodo1, @megaTodo2]

    it "fires onAdd events", ->
      eventArgs = null
      @todoList.addEvent "add", -> eventArgs = Array.from( arguments )
      @todoList.combine [@todo2, @megaTodo1]
      expect( eventArgs ).toEqualArray [@todoList, [@todo2, @megaTodo1], "end"]
      # Fires if only one model isn't in array yet
      eventArgs = null
      @todoList.combine [@megaTodo1, @megaTodo2]
      expect( eventArgs ).toEqualArray [@todoList, [@megaTodo2], "end"]
      # Doesn't fire if all models are already in array
      eventArgs = null
      @todoList.combine [@todo2]
      expect( eventArgs ).toBeNull()

  # Adding
  # ------

  describe "#pop", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2, @megaTodo1, @megaTodo2

    it "removes objects", ->
      expect( @todoList.pop() ).toBe @megaTodo2
      expect( @todoList ).toEqualArray [@todo1, @todo2, @megaTodo1]

    it "fires onRemoveEvents", ->
      eventArgs = null
      @todoList.addEvent "remove", -> eventArgs = Array.from( arguments )
      @todoList.pop()
      expect( eventArgs ).toEqualArray [@todoList, [@megaTodo2], "end"]

  describe "#shift", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2, @megaTodo1, @megaTodo2

    it "removes objects", ->
      expect( @todoList.shift() ).toBe @todo1
      expect( @todoList ).toEqualArray [@todo2, @megaTodo1, @megaTodo2]

    it "fires onRemoveEvents", ->
      eventArgs = null
      @todoList.addEvent "remove", -> eventArgs = Array.from( arguments )
      @todoList.shift()
      expect( eventArgs ).toEqualArray [@todoList, [@todo1], "beginning"]

  describe "#erase", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2, @megaTodo1, @megaTodo2, @todo2

    it "removes objects", ->
      expect( @todoList.erase( @todo2 ) ).toBe @todoList
      expect( @todoList ).toEqualArray [@todo1, @megaTodo1, @megaTodo2]

    it "can't remove non-model objects yet", ->
      # TODO: Figure out what's up with Jasmine's toThrow() matcher.
      thrownError = null
      try
        @todoList.erase( {cool: true} )
      catch error
        thrownError = error
      expect( thrownError.name ).toEqual "ModelRequired"

    it "fires onRemoveEvents", ->
      eventArgs = null
      @todoList.addEvent "remove", -> eventArgs = Array.from( arguments )
      @todoList.erase( @todo2 )
      expect( eventArgs ).toEqualArray [@todoList, [@todo2], [4, 1]]

  describe "empty", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2

    it "removes all models", ->
      expect( @todoList.empty() ).toBe( @todoList )
      expect( @todoList ).toEqualArray( [] )

    it "fires an onRemove event", ->
      eventArgs = null
      @todoList.addEvent "remove", -> eventArgs = Array.from( arguments )
      @todoList.empty()
      expect( eventArgs ).toEqualArray [@todoList, [@todo1, @todo2], "all"]
      eventArgs = null
      @todoList.empty()
      expect( eventArgs ).toBeNull()

  describe "splice", ->
    beforeEach ->
      @todoList = new @CombinedTodoList @todo1, @todo2

    it "does nothing", ->
      expect( @todoList.splice( 1, 0 ) ).toEqualArray []
      expect( @todoList ).toEqualArray( [@todo1, @todo2] )

    it "removes a model", ->
      expect( @todoList.splice( 1, 1 ) ).toEqualArray [@todo2]
      expect( @todoList ).toEqualArray( [@todo1] )

    it "removes multiple models", ->
      @todoList.push( @megaTodo1, @megaTodo2 )
      expect( @todoList.splice( 1, 2 ) ).toEqualArray [@todo2, @megaTodo1]
      expect( @todoList ).toEqualArray [@todo1, @megaTodo2]

    it "removes models", ->
      expect( @todoList.splice( 1, 2 ) ).toEqualArray [@todo2]

    it "adds a model", ->
      expect( @todoList.splice( 1, 0, @megaTodo1 ) ).toEqualArray []
      expect( @todoList ).toEqualArray [@todo1, @megaTodo1, @todo2]

    it "adds multtiple models", ->
      expect( @todoList.splice( 1, 0, @megaTodo1, @megaTodo2 ) ).toEqualArray []
      expect( @todoList ).toEqualArray [@todo1, @megaTodo1, @megaTodo2, @todo2]

    it "removes and adds models", ->
      

    it "IS KIND OF WACKY TBH", ->
      

    it "fires remove events", ->
      

    it "fires add events", ->
      

    it "fires both events", ->
      

    # TODO

  # Nested events
  # -------------

  describe "model events", ->
    it "bubbles change events", ->
      # TODO

    it "stops bubbling events when removed", ->
      # TODO

    it "fires events only once when model is in list multiple times"
      # TODO

  # Sorting
  # -------

  describe "sorting", ->
    # TODO
