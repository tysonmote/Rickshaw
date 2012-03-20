describe "ListController", ->
  beforeEach resetRickshaw

  describe "creating", ->
    beforeEach Fixtures.todoListController

    it "can be created with a list", ->
      todoListController = new @TodoListController( @todoList )
      expect( todoListController.list ).to.be( @todoList )
      expect( $( "test" ).innerHTML ).to.be.empty()

    it "can be created without a list", ->
      todoListController = new @TodoListController()
      expect( todoListController.list ).to.be( null )
      todoListController.setList( @todoList )
      expect( todoListController.list ).to.be( @todoList )
      expect( $( "test" ).innerHTML ).to.be.empty()

  describe "pre-attached events", ->
    it "attaches on initialize", ->
      MyListController = new ListController( onMyEvent: -> )
      controller = new MyListController()
      event = new EventCapture controller, "myEvent"
      controller.fireEvent( "myEvent", [1, "cool"] )
      expect( event.timesFired ).to.be( 1 )
      expect( event.arguments ).to.matchArray( [1, "cool"] )

  # describe "list events", ->
  #   beforeEach Fixtures.todoListController
  #   beforeEach ->
  #     @todoListController = new @TodoListController( @todoList )
  #     @onModelsAdd = sinon.spy( @todoListController, "_onModelsAdd" )
  #     @onModelRemove = sinon.spy( @todoListController, "_onModelsRemove" )
  # 
  #   it "attaches events to the list", ->
  #     @todo3 = new @Todo()
  #     @todoList.push( @todo3 )
  #     expect( @onModelsAdd ).to.have.been.calledOnce()
  #     expect( @onModelsAdd ).to.have.been.calledWith([ @todoList, [@todo3], "end" ])
  # 
  #     @todoList.pop()
  #     expect( @onModelRemove ).to.have.been.calledOnce()
  #     expect( @onModelRemove ).to.have.been.calledWith([ @todoList, [@todo1], "omg" ])
  # 
  #   it "attaches events to a new list, when set"

  describe "rendering", ->
    beforeEach Fixtures.todoListController
    beforeEach ->
      @todoListController = new @TodoListController( @todoList, $( "test" ) )

    it "renders the list", ->
      expect( $$( "#test > div.todos > p" ).length ).to.be( 2 )
      expect( $$( "#test > div.todos > p" )[1].innerHTML ).to.be( "#2" )

    it "updates when a new list item is pushed", ->
      @todoList.push({ num: 3 })
      expect( $$( "#test > div.todos > p" ).length ).to.be( 3 )
      expect( $$( "#test > div.todos > p" )[2].innerHTML ).to.be( "#3" )

    it "updates when multiple list items are pushed", ->
      @todoList.push({ num: 3 }, { num: 4 })
      expect( $$( "#test > div.todos > p" ).length ).to.be( 4 )
      expect( $$( "#test > div.todos > p" )[3].innerHTML ).to.be( "#4" )

    it "updates when a list item is popped", ->
      @todoList.push({ num: 3 }, { num: 4 })
      @todoList.pop()
      expect( $$( "#test > div.todos > p" ).length ).to.be( 3 )
      expect( $$( "#test > div.todos > p" )[2].innerHTML ).to.be( "#3" )

    it "updates when a list items is shifted", ->
      @todoList.push({ num: 3 }, { num: 4 })
      @todoList.shift()
      expect( $$( "#test > div.todos > p" ).length ).to.be( 3 )
      expect( $$( "#test > div.todos > p" )[0].innerHTML ).to.be( "#2" )

    it "updates when multiple list items are spliced from the end", ->
      @todoList.push({ num: 3 }, { num: 4 }, { num: 5 })
      @todoList.splice( 3, 2 )
      expect( $$( "#test > div.todos > p" ).length ).to.be( 3 )
      expect( $$( "#test > div.todos > p" )[2].innerHTML ).to.be( "#3" )

    it "updates when multiple list items are spliced from the beginning", ->
      @todoList.push({ num: 3 }, { num: 4 }, { num: 5 })
      @todoList.splice( 0, 2 )
      expect( $$( "#test > div.todos > p" ).length ).to.be( 3 )
      expect( $$( "#test > div.todos > p" )[0].innerHTML ).to.be( "#3" )

    it "updates when multiple list items are spliced from the middle", ->
      @todoList.push({ num: 3 }, { num: 4 }, { num: 5 })
      @todoList.splice( 1, 2 )
      expect( $$( "#test > div.todos > p" ).length ).to.be( 3 )
      expect( $$( "#test > div.todos > p" )[0].innerHTML ).to.be( "#1" )
      expect( $$( "#test > div.todos > p" )[1].innerHTML ).to.be( "#4" )

    it "updates when multiple list items are spliced in and out", ->
      @todoList.push({ num: 3 }, { num: 4 }, { num: 5 }, { num: 6 } )
      @todoList.splice( 1, 2, { num: 7 }, { num: 8 } )
      expect( $$( "#test > div.todos > p" ).length ).to.be( 6 )
      expect( $$( "#test > div.todos > p" )[0].innerHTML ).to.be( "#1" )
      expect( $$( "#test > div.todos > p" )[1].innerHTML ).to.be( "#7" )
      expect( $$( "#test > div.todos > p" )[2].innerHTML ).to.be( "#8" )
      expect( $$( "#test > div.todos > p" )[3].innerHTML ).to.be( "#4" )

    it "updates when multiple list items are spliced in and out at the beginning", ->
      @todoList.push({ num: 3 }, { num: 4 }, { num: 5 }, { num: 6 } )
      @todoList.splice( 0, 4, { num: 7 }, { num: 8 } )
      expect( $$( "#test > div.todos > p" ).length ).to.be( 4 )
      expect( $$( "#test > div.todos > p" )[0].innerHTML ).to.be( "#7" )
      expect( $$( "#test > div.todos > p" )[1].innerHTML ).to.be( "#8" )
      expect( $$( "#test > div.todos > p" )[2].innerHTML ).to.be( "#5" )
      expect( $$( "#test > div.todos > p" )[3].innerHTML ).to.be( "#6" )

    it "updates when multiple list items are spliced in and out at the end", ->
      @todoList.push({ num: 3 }, { num: 4 }, { num: 5 }, { num: 6 } )
      @todoList.splice( 3, 3, { num: 7 }, { num: 8 } )
      expect( $$( "#test > div.todos > p" ).length ).to.be( 5 )
      expect( $$( "#test > div.todos > p" )[1].innerHTML ).to.be( "#2" )
      expect( $$( "#test > div.todos > p" )[2].innerHTML ).to.be( "#3" )
      expect( $$( "#test > div.todos > p" )[3].innerHTML ).to.be( "#7" )
      expect( $$( "#test > div.todos > p" )[4].innerHTML ).to.be( "#8" )

    it "updates when the list is emptied"
    it "updates when a model is erased"