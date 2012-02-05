// Models
Todo = new Model();
TodoList = new Rickshaw.List({ ModelClass: Todo });

// Controllers
TodoController = new Rickshaw.Controller({
  Template: "todo",
  Events: { li: { click: function() { console.log( this, arguments ); } } },
  content: function() { return "#" + this.model.get( "index" ); }
});
TodoListController = new Rickshaw.ListController({
  Template: "todos",
  Subcontroller: TodoController
});
