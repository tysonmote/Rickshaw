---
layout: page
title: Rickshaw.js
---

Rickshaw.js is an in-progress client-side MVC framework based on MooTools. The ultimate aim is to create an MVC framework that is fun to use. That means Rickshaw.js will have a simple API and will eliminate boilerplate wherever possible. Also: MooTools <3

More information is coming soon, as Rickshaw.js is a work in progress. See the [GitHub page](github.com/tysontate/Rickshaw) for more information.

## Rickshaw.Model

Rickshaw Models are what you expect them to be: thin wrapper objects for your data, with no ties to the interface (views). Models keep track of dirty attribute states, fire events when properties are changed, and allow you to set defaults and use custom getters and setters.

## Rickshaw.List

Rickshaw List objects are Array subclasses that fire events. These events are used in tandem with Rickshaw.ListController for rendering to the DOM to make updates fast and easy. When an item is added / changed / removed, only that item is rendered / updated / removed instead of re-rendering the entire list. You don't have to worry about what happens when you push / pop / splice / sort / reverse or write your own rendering code. Just modify the array like you would any other array and the interface updates automatically.

## Rickshaw.Controller and ListController

Rickshaw controllers are the interface between your models / lists and your templates. Your templates shouldn't have to ever touch your models (even though Rickshaw will let you live on the edge just to feel alive).

## Todo list example

Apparently there's some sort of law that requires client-side MVC frameworks to include a todo list example. So, uh, here you go.

### Model and list

{% highlight coffeescript %}
Todo = new Rickshaw.Model(
  isDone: -> !!this.get( "done" )
)
TodoList = new Rickshaw.List( ModelClass: Todo )
{% endhighlight %}

### Controllers

{% highlight coffeescript %}
TodoController = new Rickshaw.Controller(
  Template: "todo"
  DeferToModel: ["text"]
  Events:
    li: click: -> this.toggle "done"
  klass: -> if @model.isDone() then "done" else ""
)

TodoListController = new Rickshaw.ListController(
  Template: "todos"
  Subcontroller: TodoController
  Events:
    "input#new-todo": keydown: "newTodoKeydown"
  newTodoKeydown: (e, el) ->
    if e.key == "enter"
      e.preventDefault()
      @list.push el.get( "value" )
      el.set "value", ""
)
{% endhighlight %}

### Templates

{% highlight html %}
<!-- todos -->
<h1>Todos:</h1>
{{ list "ul.todos" }}
<input id="new-todo" type="text" />

<!-- todo -->
<li class="{{ klass }}">{{ text }}</li>
{% endhighlight %}

### Bootstrap

{% highlight coffeescript %}
document.addEvent "domready", ->
  new TodoListController( new TodoList(), document.body )
{% endhighlight %}

And that's it &mdash; your standard issue MVC-based todo list example.
