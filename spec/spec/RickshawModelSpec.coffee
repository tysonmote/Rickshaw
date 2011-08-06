describe "Rickshaw.Model", ->
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
      
      it "Sets data", ->
        @todo.set( "foo", "bar" )
        expect( @todo.data ).toEqual({
          "foo": "bar"
        })
      
      it "Gets undefined data", ->
        expect( @todo.get( "foo" ) ).toBeUndefined()
      
    describe "With data", ->
      beforeEach ->
        @todo = new @Todo({
          id: 123
          foo: "bar"
          baz: true
        })
      
    describe "With data and no id property", ->
      beforeEach ->
        @todo = new @Todo({
          foo: "bar"
          baz: true
        })
