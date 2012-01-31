Rickshaw
========

Rickshaw is small but full-featured client-side MVC framework using (and
adhering to the idioms of) [MooTools][mootools] for models and controllers and
[Handlebars][handlebars] for templating (views).

Example
-------

Here is a brief to-do list example, as is required by law:

**Model and List**

    Todo = new Rickshaw.Model(
      isDone: -> !!this.get( "done" )
    )
    TodoList = new Rickshaw.List( ModelClass: Todo )

Rickshaw Model instances are pretty much what you expect them to be: your data,
with no real ties to the interface (a.k.a. views), although you may want to use
custom getters and setters to make working with your back-end models easier.

Rickshaw List objects are Array subclasses that fire events and create model
instances automatically when given raw data. This makes rendering them easy
because you don't have to worry about what happens when you push / pop /
splice / sort / reverse, etc. Just modify the array and the interface updates
automatically.

**Controller**

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

Rickshaw controllers are the interface between your models / lists and your
templates. Your templates shouldn't have to ever touch your models (even
though Rickshaw will let you, if you want to just to feel alive).

**Templates**

"todos"

    <h1>Todos:</h1>
    {{ list "ul.todos" }}
    <input id="new-todo" type="text" />

"todo"

    <li class="{{ klass }}">{{ text }}</li>

**Bootstrapping**

    document.addEvent "domready", ->
      new TodoListController( new TodoList(), document.body )

That's it.

[mootools]: http://mootools.net
[handlebars]: http://handlebarsjs.com/

General Philosophy
------------------

MooTools is great, JavaScript is good, and boilerplate is bad.

To do
-----

(Roughly in order of importance)

* Specs for:
  * ListController
    * Lots of spec fun to be had with the list item subcontrollers + event delegation, and so on.
  * Handlebars extensions
* Make ListController re-rendering more efficient when sorting or reversing the list
* Audit use of UUIDs -- can probably get rid of a lot of this.
* Some sort of pluggable persistance backend
  * RESTful, WebSockets, LocalStorage, etc.
  * Should make it easy to define your own and subclass them, especially for
    WebSockets if you want to implement your own message protocol.
* Auto-updating selector bindings
  * If I add an event on "div.rad" and that "rad" class is bound, the events
    should automatically be removed. I think the solution here is to wrap all
    added events with a function that re-checks for selector match before
    firing.
* Form bindings
  * You should be able to make create / edit forms super easily and never
    have to worry about maintaining bindings / events
* Better model change bindings
  * Ember.js-style might be overly ambitious / heavy, but it's worth
    investigation

Specs
-----

If you want to run the specs headlessly (warning: `qt` is fairly hefty):

    brew update
    brew install qt
    bundle install
    bundle exec evergreen run

Or if you don't want / need to run them headlessly:

    rm .evergreen
    bundle install --without headless
    bundle exec evergreen serve

(`.evergreen` simply has the config for headless specs. Removing that file
will tell `evergreen` to default to Selenium.)

Contributors
------------

* Tyson Tate
* Casey Speer - Early contributions to the persistence layer.
