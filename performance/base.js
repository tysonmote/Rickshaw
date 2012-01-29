// Models
Todo = new Rickshaw.Model();
Todo.NAME = "Todo";
TodoList = new Rickshaw.List({ ModelClass: Todo });
TodoList.NAME = "TodoList";

// Controllers
TodoController = new Rickshaw.Controller({
  Template: "todo",
  Events: { li: { click: function() { console.log( this ); } } },
  content: function() { return "#" + this.model.get( "index" ); }
});
TodoController.NAME = "TodoController";
TodoListController = new Rickshaw.ListController({
  Template: "todos",
  Subcontroller: TodoController
});
TodoListController.NAME = "TodoListController";
