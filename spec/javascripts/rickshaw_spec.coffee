require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Rickshaw", ->
  describe "UUIDs", ->
    UUID_REGEX = /^rickshaw-[0-9a-f]{8}-[0-9a-f]{8}$/

    it "generates unique UUIDs", ->
      expect( Rickshaw.uuid() ).toMatch( UUID_REGEX )
      expect( Rickshaw.uuid() == Rickshaw.uuid() ).toBe( false )

    it "registers objects and finds", ->
      thing = {}
      Rickshaw.register( thing )
      expect( thing.$uuid ).toMatch( UUID_REGEX )
      expect( Rickshaw.get( thing.$uuid ) ).toBe( thing )

    it "adds a reference to an instance's parent class", ->
      Foo = new Class({})
      Rickshaw.register( Foo )
      foo = new Foo()
      Rickshaw.addParentClass( foo )
      expect( foo._class ).toBe( Foo )

  describe "template loading", ->
    it "auto-detects and compiles templates", ->
      # TODO

    it "re-detects and compiles templates", ->
      # TODO

describe "Rickshaw.Utils", ->
  describe "#equal()", ->
    it "determines if basic primitives are equal", ->
      expect( Rickshaw.Utils.equal( 0, 0 ) ).toBe( true )
      expect( Rickshaw.Utils.equal( 1, 2 ) ).toBe( false )
      expect( Rickshaw.Utils.equal( "1", "1" ) ).toBe( true )
      expect( Rickshaw.Utils.equal( "1", 1 ) ).toBe( false )
      expect( Rickshaw.Utils.equal( 1, "1" ) ).toBe( false )
      expect( Rickshaw.Utils.equal( 0, false ) ).toBe( false )

    it "determines if arrays are equal", ->
      expect( Rickshaw.Utils.equal( [], [] ) ).toBe( true )
      expect( Rickshaw.Utils.equal( [1, "2"], [1, "2"] ) ).toBe( true )
      expect( Rickshaw.Utils.equal( [1, 0], [1, false] ) ).toBe( false )
      expect( Rickshaw.Utils.equal( [1, []], [1, false] ) ).toBe( false )
      expect( Rickshaw.Utils.equal( [1, [2, "3", {a:"b"}]], [1, [2, "3", {a:"b"}]] ) ).toBe( true )

    it "determines if objects are equal", ->
      expect( Rickshaw.Utils.equal( {a: 1}, {a: 1} ) ).toBe( true )
      expect( Rickshaw.Utils.equal( {a: [1, 2]}, {a: [1, 2]} ) ).toBe( true )
      expect( Rickshaw.Utils.equal( {a: [1, {a:"b"}]}, {a: [1, {a:"b"}]} ) ).toBe( true )
      expect( Rickshaw.Utils.equal( {a: [1, {a:"b"}]}, {a: [{a:"b"}, 1]} ) ).toBe( false )
      expect( Rickshaw.Utils.equal( {a: [1, 2]}, {a: [1, [2]]} ) ).toBe( false )
      expect( Rickshaw.Utils.equal( {a: []}, {a: false} ) ).toBe( false )
      expect( Rickshaw.Utils.equal( {a: 1}, ["a", 1] ) ).toBe( false )

  describe "#isModelInstance()", ->
    it "tells you if an object is a model instance", ->
      expect( Rickshaw.Utils.isModelInstance( 1 ) ).toBe( false )
      expect( Rickshaw.Utils.isModelInstance( {} ) ).toBe( false )
      expect( Rickshaw.Utils.isModelInstance( Rickshaw.Model ) ).toBe( false )
      expect( Rickshaw.Utils.isModelInstance( new Rickshaw.Model() ) ).toBe( false )
      expect( Rickshaw.Utils.isModelInstance( new (new Rickshaw.Model())() ) ).toBe( true )

  describe "#findController()", ->
    beforeEach ->
      @Todo = new Rickshaw.Model()
      @todo = new @Todo()
      rickshawTemplate "todo", "
        <p>Rad.</p>
      "
      @TodoController = new Rickshaw.Controller(
        Template: "todo"
        Events: p: click: -> console.log "SHIT"
      )
      @todoController = new @TodoController( @todo, $( "test" ) )

    it "returns the correct controller instance for an element + event function", ->
      element = $( "test" ).getElement( "p" )
      event = @TodoController.prototype.Events.p.click
      expect( Rickshaw.Utils.findController( element, event, "p", "click" ) ).toBe( @todoController )
      try
        Rickshaw.Utils.findController( element, (->), "p", "click" )
        throw "Nothing was raised, but we expected an error."
      catch error
        # pass
      try
        Rickshaw.Utils.findController( element, event, "404", "click" )
        throw "Nothing was raised, but we expected an error."
      catch error
        # pass
      try
        Rickshaw.Utils.findController( element, event, "p", "404" )
        throw "Nothing was raised, but we expected an error."
      catch error
        # pass

describe "MooTools extensions", ->
  describe "String", ->
    it "forces camel case", ->
      expect( "this is-the_remix".forceCamelCase() ).toEqual( "thisIsTheRemix" )

  describe "Array", ->
    it "maps properties", ->
      array = [{}, {a:1}, {a:2}, {a:3}]
      expect( array.mapProperty( "a" ) ).toEqual( [undefined, 1, 2, 3] )
