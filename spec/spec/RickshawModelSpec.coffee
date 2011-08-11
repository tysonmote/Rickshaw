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
    
    describe "Custom getters", ->
      beforeEach ->
        @CustomSetterTodo = new Class({
          Extends: @Todo
          
          getters:
            foo: -> true
            bound: -> @isBound
        })
        @todo = new @CustomSetterTodo({
          foo: false
        })
      
      it "Uses custom getter", ->
        expect( @todo.get( "foo" ) ).toBe( true )
        expect( @todo.data.foo ).toBe( false )
      
      it "Binds custom getter to the instance", ->
        @todo.isBound = true
        expect( @todo.get( "bound" ) ).toBe( true )
  
  # ===========
  # = Setting =
  # ===========
  
  describe "Setting", ->
    beforeEach ->
      @Todo = new Class({
        Extends: Rickshaw.Model
      })
    
    describe "With no data", ->
      beforeEach ->
        @todo = new @Todo()
      
      it "Sets data", ->
        @todo.set( "foo", "bar" )
        expect( @todo.data ).toEqual({ foo: "bar" })
      
      it "Marks record as dirty", ->
        @todo.set( "foo", "bar" )
        expect( @todo.isDirty() ).toBe( true )
      
      it "Fires dataChange event", ->
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set( "foo", true )
        expect( fired ).toBe( true )
      
      it "Accepts object params", ->
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set({ foo: true, bar: true })
        expect( fired ).toBe( true )
        expect( @todo.isDirty() ).toBe( true )
        expect( @todo.data ).toEqual({ foo: true, bar: true })
    
    describe "With data", ->
      beforeEach ->
        @todo = new @Todo({
          id: 123
          foo: "bar"
        })
      
      it "Overwrites properties", ->
        @todo.set( "foo", "doo" )
        expect( @todo.get( "foo" ) ).toEqual( "doo" )
      
      it "Marks record as dirty", ->
        @todo.set( "foo", "doo" )
        expect( @todo.isDirty() ).toBe( true )
      
      it "Fires dataChange event", ->
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set( "foo", true )
        expect( fired ).toBe( true )
      
      it "Doesn't fire dataChange event if value doesn't change", ->
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set( "foo", "bar" )
        expect( fired ).toBe( false )
    
    describe "Custom setters", ->
      beforeEach ->
        @CustomSetterTodo = new Class({
          Extends: @Todo
          
          setters:
            foo: (value) ->
              @data["foo"] = "value: #{value}"
            bound: (value) ->
              @boundValue = value
        })
        @todo = new @CustomSetterTodo({
          foo: "baz"
        })
      
      it "Uses custom setter", ->
        @todo.set( "foo", "bar" )
        expect( @todo.get( "foo" ) ).toEqual( "value: bar" )
      
      it "Binds custom getter to the instance", ->
        @todo.set( "bound", true )
        expect( @todo.boundValue ).toBe( true )
      
      it "Marks record as dirty", ->
        @todo.set( "foo", "bar" )
        expect( @todo.isDirty() ).toBe( true )
      
      it "Fires dataChange event", ->
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set( "foo", "bar" )
        expect( fired ).toBe( true )
        fired = false
        @todo.set( "foo", "bar" )
        expect( fired ).toBe( false )
      
      it "Doesn't fire dataChange event if value doesn't change", ->
        @todo.set( "foo", "bar" )
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set( "foo", "bar" )
        expect( fired ).toBe( false )
        
      it "Accepts object params", ->
        fired = false
        @todo.addEvent( "dataChange", -> fired = true )
        @todo.set({ foo: "A", bar: "B" })
        expect( fired ).toBe( true )
        expect( @todo.isDirty() ).toBe( true )
        expect( @todo.data ).toEqual({ foo: "value: A", bar: "B" })
  
  # ============================
  # = Property change handlers =
  # ============================
  
  describe "Property change handlers", ->
    beforeEach ->
      @Todo = new Class({
        Extends: Rickshaw.Model
        
        onCoolDescriptionChange: ->
          @hookFired = true
      })
    
    describe "With no data", ->
      beforeEach ->
        @todo = new @Todo(( "cool-description": "bar" ))
      
      it "Fires the hook", ->
        expect( @todo.hookFired ).toBe( undefined )
        @todo.set( "cool-description", "bizzle" )
        expect( @todo.hookFired ).toBe( true )
      
      it "Doesn't fire hook erroneously", ->
        @todo.set( "cool-description", "bar" )
        expect( @todo.hookFired ).toBe( undefined )
