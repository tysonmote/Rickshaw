describe "Rickshaw.Model", ->
  
  # =================
  # = Instantiation =
  # =================
  
  describe "Instantiation", ->
    beforeEach ->
      @Todo = new Class({
        Extends: Rickshaw.Model
      })
    
    describe "With no data", ->
      beforeEach ->
        @todo = new @Todo()
      
      it "Has no data", ->
        expect( @todo.data ).toEqual( {} )
      
      it "Has no id", ->
        expect( @todo.id ).toBeUndefined()
      
      it "Is not dirty", ->
        expect( @todo.isDirty() ).toBe( false )
      
    describe "With data and id", ->
      beforeEach ->
        @todo = new @Todo({
          id: 123
          foo: "bar"
          baz: true
        })
      
      it "Has data", ->
        expect( @todo.data ).toEqual({
          id: 123
          foo: "bar"
          baz: true
        })
      
      it "Sets id on instantiation", ->
        expect( @todo.id ).toEqual( 123 )
      
      it "Is not dirty", ->
        expect( @todo.isDirty() ).toBe( false )
      
    describe "With data and no id property", ->
      beforeEach ->
        @todo = new @Todo({
          foo: "bar"
          baz: true
        })
      
      it "Has data", ->
        expect( @todo.data ).toEqual({
          foo: "bar"
          baz: true
        })
      
      it "Has no id", ->
        expect( @todo.id ).toBeUndefined()
      
      it "Is not dirty", ->
        expect( @todo.isDirty() ).toBe( false )
  
  # ===========
  # = Getting =
  # ===========
  
  describe "Getting", ->
    beforeEach ->
      @Todo = new Class({
        Extends: Rickshaw.Model
      })
    
    describe "With no data", ->
      beforeEach ->
        @todo = new @Todo()
      
      it "Gets empty data", ->
        expect( @todo.data ).toEqual( {} )
      
      it "Gets undefined property", ->
        expect( @todo.get( "foo" ) ).toBeUndefined()
      
    describe "With data and id", ->
      beforeEach ->
        @todo = new @Todo({
          id: 123
          foo: "bar"
          baz: true
        })
      
      it "Gets properties", ->
        expect( @todo.get( "foo" ) ).toEqual( "bar" )
      
      it "Gets all data", ->
        expect( @todo.data ).toEqual({
          id: 123
          foo: "bar"
          baz: true
        })
