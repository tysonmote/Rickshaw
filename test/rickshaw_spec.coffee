describe "Rickshaw", ->
  beforeEach resetRickshaw

  describe "template loading", ->
    it "auto-detects and compiles templates"

    it "re-detects and compiles templates"

  describe "UUIDs", ->
    UUID_REGEX = /^rickshaw-[0-9]+$/

    it "generates unique UUIDs", ->
      expect( Rickshaw.uuid() ).to.match( UUID_REGEX )
      expect( Rickshaw.uuid() == Rickshaw.uuid() ).to.be( false )

    it "adds a UUID to an object", ->
      obj = {}
      Rickshaw.addUuid( obj )
      expect( obj.$uuid ).to.match( UUID_REGEX )

  describe "#typeOf()", ->
    it "returns the correct type of primitives", ->
      expect( Rickshaw.typeOf( {a:1} ) ).to.be( "object" )
      expect( Rickshaw.typeOf( [1] ) ).to.be( "array" )
      expect( Rickshaw.typeOf( "1" ) ).to.be( "string" )
      expect( Rickshaw.typeOf( /1/ ) ).to.be( "regexp" )
      expect( Rickshaw.typeOf( -> ) ).to.be( "function" )
      expect( Rickshaw.typeOf( 1 ) ).to.be( "number" )
      expect( Rickshaw.typeOf( true ) ).to.be( "boolean" )

    it "returns the correct type of non-primitives", ->
      expect( Rickshaw.typeOf( new Date() ) ).to.be( "date" )
      expect( Rickshaw.typeOf( new Class({}) ) ).to.be( "class" )
      expect( Rickshaw.typeOf( new Element("div") ) ).to.be( "element" )

    it "returns the correct type of Rickshaw objects", ->
      Todo = new Model({})
      todo = new Todo({})
      TodoList = new List()
      todoList = new TodoList()
      TodoController = new Controller({})
      todoController = new TodoController( todo )
      TodoListController = new ListController({})
      todoListController = new TodoListController( todoList )
      expect( Rickshaw.typeOf( Todo ) ).to.be( "class" )
      expect( Rickshaw.typeOf( todo ) ).to.be( "Model" )
      expect( Rickshaw.typeOf( TodoList ) ).to.be( "class" )
      expect( Rickshaw.typeOf( todoList ) ).to.be( "List" )
      expect( Rickshaw.typeOf( TodoController ) ).to.be( "class" )
      expect( Rickshaw.typeOf( todoController ) ).to.be( "Controller" )
      expect( Rickshaw.typeOf( TodoListController ) ).to.be( "class" )
      expect( Rickshaw.typeOf( todoListController ) ).to.be( "ListController" )

  describe "#clone()", ->
    beforeEach ->
      @arrayCloneMethod = sinon.spy( Array, "clone" )
      @objectCloneMethod = sinon.spy( Object, "clone" )

    afterEach ->
      @arrayCloneMethod.restore()
      @objectCloneMethod.restore()

    it "uses Array.clone() for arrays", ->
      array = [1, {a: ["a"]}]
      expect( Rickshaw.clone( array ) ).not.to.be( array )
      expect( Rickshaw.clone( array ) ).to.eql( array )
      expect( @arrayCloneMethod ).to.have.been.calledWith( array )

    it "uses Object.clone() for objects", ->
      object = {a: 1, b: {c: "d"}}
      expect( Rickshaw.clone( object ) ).not.to.be( object )
      expect( @objectCloneMethod ).to.have.been.calledWith( object )

  describe "#equal()", ->
    it "determines if basic primitives are equal", ->
      expect( Rickshaw.equal( 0, 0 ) ).to.be( true )
      expect( Rickshaw.equal( 1, 2 ) ).to.be( false )
      expect( Rickshaw.equal( "1", "1" ) ).to.be( true )
      expect( Rickshaw.equal( "1", 1 ) ).to.be( false )
      expect( Rickshaw.equal( 1, "1" ) ).to.be( false )
      expect( Rickshaw.equal( 0, false ) ).to.be( false )

    it "determines if arrays are equal in value", ->
      expect( Rickshaw.equal( [], [] ) ).to.be( true )
      expect( Rickshaw.equal( [1, "2"], [1, "2"] ) ).to.be( true )
      expect( Rickshaw.equal( [1, 0], [1, false] ) ).to.be( false )
      expect( Rickshaw.equal( [1, []], [1, false] ) ).to.be( false )
      expect( Rickshaw.equal( [1, [2, "3", {a:"b"}]], [1, [2, "3", {a:"b"}]] ) ).to.be( true )
      # Don't blow the stack
      x = []
      x[0] = x
      expect( Rickshaw.equal( x, x ) ).to.be( true )

    it "determines if objects are equal", ->
      expect( Rickshaw.equal( {a: 1}, {a: 1} ) ).to.be( true )
      expect( Rickshaw.equal( {a: [1, 2]}, {a: [1, 2]} ) ).to.be( true )
      expect( Rickshaw.equal( {a: [1, {a:"b"}]}, {a: [1, {a:"b"}]} ) ).to.be( true )
      expect( Rickshaw.equal( {a: [1, {a:"b"}]}, {a: [{a:"b"}, 1]} ) ).to.be( false )
      expect( Rickshaw.equal( {a: [1, 2]}, {a: [1, [2]]} ) ).to.be( false )
      expect( Rickshaw.equal( {a: []}, {a: false} ) ).to.be( false )
      expect( Rickshaw.equal( {a: 1}, ["a", 1] ) ).to.be( false )
      # Don't blow the stack
      x = { a: 1 }
      x.b = x
      expect( Rickshaw.equal( x, x ) ).to.be( true )

  describe "#isModelInstance()", ->
    it "tells you if an object is a model instance", ->
      expect( Rickshaw.isModelInstance( 1 ) ).to.be( false )
      expect( Rickshaw.isModelInstance( {} ) ).to.be( false )
      expect( Rickshaw.isModelInstance( Model ) ).to.be( false )
      expect( Rickshaw.isModelInstance( new Model() ) ).to.be( false )
      expect( Rickshaw.isModelInstance( new (new Model())() ) ).to.be( true )

describe "MooTools extensions", ->
  describe "Array", ->
    it "maps properties", ->
      array = [{}, {a:1}, {a:2}, {a:3}]
      expect( array.mapProperty( "a" ) ).to.eql( [undefined, 1, 2, 3] )

    it "returns the first element matching a function", ->
      expect( [].first((el) -> el == 1) ).to.be( null )
      expect( [2, 3, 4].first((el) -> el == 1) ).to.be( null )
      expect( [3, 2, 1].first((el) -> el == 1) ).to.be( 1 )

  describe "String", ->
    it "forces camel case", ->
      expect( "this is-the_remix".forceCamelCase() ).to.eql( "thisIsTheRemix" )
