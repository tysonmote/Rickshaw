require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Rickshaw", ->
  describe "template loading", ->
    it "auto-detects and compiles templates", ->
      # TODO

    it "re-detects and compiles templates", ->
      # TODO

  describe "UUIDs", ->
    UUID_REGEX = /^rickshaw-[0-9]+$/

    it "generates unique UUIDs", ->
      expect( Rickshaw.uuid() ).toMatch( UUID_REGEX )
      expect( Rickshaw.uuid() == Rickshaw.uuid() ).toBe( false )

    it "adds a UUID to an object", ->
      obj = {}
      Rickshaw.addUuid( obj )
      expect( obj.$uuid ).toMatch( UUID_REGEX )

  describe "#typeOf()", ->
    it "returns the correct type of primitives", ->
      expect( Rickshaw.typeOf( {a:1} ) ).toBe( "object" )
      expect( Rickshaw.typeOf( [1] ) ).toBe( "array" )
      expect( Rickshaw.typeOf( "1" ) ).toBe( "string" )
      expect( Rickshaw.typeOf( /1/ ) ).toBe( "regexp" )
      expect( Rickshaw.typeOf( -> ) ).toBe( "function" )
      expect( Rickshaw.typeOf( 1 ) ).toBe( "number" )
      expect( Rickshaw.typeOf( true ) ).toBe( "boolean" )

    it "returns the correct type of non-primitives", ->
      expect( Rickshaw.typeOf( new Date() ) ).toBe( "date" )
      expect( Rickshaw.typeOf( new Class({}) ) ).toBe( "class" )
      expect( Rickshaw.typeOf( new Element("div") ) ).toBe( "element" )

    it "returns the correct type of Rickshaw objects", ->
      Todo = new Model({})
      todo = new Todo({})
      TodoList = new List()
      todoList = new TodoList()
      TodoController = new Controller({})
      todoController = new TodoController( todo )
      TodoListController = new ListController({})
      todoListController = new TodoListController( todoList )
      expect( Rickshaw.typeOf( Todo ) ).toBe( "class" )
      expect( Rickshaw.typeOf( todo ) ).toBe( "Model" )
      expect( Rickshaw.typeOf( TodoList ) ).toBe( "class" )
      expect( Rickshaw.typeOf( todoList ) ).toBe( "List" )
      expect( Rickshaw.typeOf( TodoController ) ).toBe( "class" )
      expect( Rickshaw.typeOf( todoController ) ).toBe( "Controller" )
      expect( Rickshaw.typeOf( TodoListController ) ).toBe( "class" )
      expect( Rickshaw.typeOf( todoListController ) ).toBe( "ListController" )

  describe "#clone()", ->
    it "uses Array.clone() for arrays", ->
      array = [1, {a: ["a"]}]
      spyOn( Array, "clone" ).andCallThrough()
      expect( Rickshaw.clone( array ) ).not.toBe( array )
      expect( Array.clone ).toHaveBeenCalledWith( array )

    it "uses Object.clone() for objects", ->
      object = {a: 1, b: {c: "d"}}
      spyOn( Object, "clone" ).andCallThrough()
      expect( Rickshaw.clone( object ) ).not.toBe( object )
      expect( Object.clone ).toHaveBeenCalledWith( object )

  describe "#equal()", ->
    it "determines if basic primitives are equal", ->
      expect( Rickshaw.equal( 0, 0 ) ).toBe( true )
      expect( Rickshaw.equal( 1, 2 ) ).toBe( false )
      expect( Rickshaw.equal( "1", "1" ) ).toBe( true )
      expect( Rickshaw.equal( "1", 1 ) ).toBe( false )
      expect( Rickshaw.equal( 1, "1" ) ).toBe( false )
      expect( Rickshaw.equal( 0, false ) ).toBe( false )

    it "determines if arrays are equal in value", ->
      expect( Rickshaw.equal( [], [] ) ).toBe( true )
      expect( Rickshaw.equal( [1, "2"], [1, "2"] ) ).toBe( true )
      expect( Rickshaw.equal( [1, 0], [1, false] ) ).toBe( false )
      expect( Rickshaw.equal( [1, []], [1, false] ) ).toBe( false )
      expect( Rickshaw.equal( [1, [2, "3", {a:"b"}]], [1, [2, "3", {a:"b"}]] ) ).toBe( true )
      # Don't blow the stack
      x = []
      x[0] = x
      expect( Rickshaw.equal( x, x ) ).toBe( true )

    it "determines if objects are equal", ->
      expect( Rickshaw.equal( {a: 1}, {a: 1} ) ).toBe( true )
      expect( Rickshaw.equal( {a: [1, 2]}, {a: [1, 2]} ) ).toBe( true )
      expect( Rickshaw.equal( {a: [1, {a:"b"}]}, {a: [1, {a:"b"}]} ) ).toBe( true )
      expect( Rickshaw.equal( {a: [1, {a:"b"}]}, {a: [{a:"b"}, 1]} ) ).toBe( false )
      expect( Rickshaw.equal( {a: [1, 2]}, {a: [1, [2]]} ) ).toBe( false )
      expect( Rickshaw.equal( {a: []}, {a: false} ) ).toBe( false )
      expect( Rickshaw.equal( {a: 1}, ["a", 1] ) ).toBe( false )
      # Don't blow the stack
      x = { a: 1 }
      x.b = x
      expect( Rickshaw.equal( x, x ) ).toBe( true )

  describe "#isModelInstance()", ->
    it "tells you if an object is a model instance", ->
      expect( Rickshaw.isModelInstance( 1 ) ).toBe( false )
      expect( Rickshaw.isModelInstance( {} ) ).toBe( false )
      expect( Rickshaw.isModelInstance( Model ) ).toBe( false )
      expect( Rickshaw.isModelInstance( new Model() ) ).toBe( false )
      expect( Rickshaw.isModelInstance( new (new Model())() ) ).toBe( true )

describe "MooTools extensions", ->
  describe "Array", ->
    it "maps properties", ->
      array = [{}, {a:1}, {a:2}, {a:3}]
      expect( array.mapProperty( "a" ) ).toEqual( [undefined, 1, 2, 3] )

    it "returns the first element matching a function", ->
      expect( [].first((el) -> el == 1) ).toBeNull()
      expect( [2, 3, 4].first((el) -> el == 1) ).toBeNull()
      expect( [3, 2, 1].first((el) -> el == 1) ).toBe(1)

  describe "String", ->
    it "forces camel case", ->
      expect( "this is-the_remix".forceCamelCase() ).toEqual( "thisIsTheRemix" )
