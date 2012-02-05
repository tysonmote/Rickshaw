// Models
Todo = new Model();
TodoList = new List({ ModelClass: Todo });

// Controllers
TodoController = new Controller({
  Template: "todo",
  Events: { li: { click: function() { console.log( this, arguments ); } } },
  content: function() { return "#" + this.model.get( "index" ); }
});
TodoListController = new ListController({
  Template: "todos",
  Subcontroller: TodoController
});
