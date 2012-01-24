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
    TodoList = new Rickshaw.List( modelClass: Todo )

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
      templateName: "todo"
      klass: -> if @model.isDone() then "done" else ""
      text: -> @model.get( "text" )
      events:
        li:
          click: -> this.set( "done", !this.get( "done" ) )
    )
    
    TodoListController = new Rickshaw.ListController(
      templateName: "todos"
      subcontroller: TodoController
      events:
        "input#new-todo":
          keydown: "newTodoKeydown"
      newTodoKeydown: (e, el) ->
        if e.key == "enter"
          e.preventDefault()
          @list.push( el.get( "value" ) )
          el.set( "value", "" )
    )

Rickshaw controllers are the interface between your models / lists and your
templates. Your templates shouldn't have to ever touch your models (even
though Rickshaw will let you, if you want to just to feel alive).

**Templates**

"todos"

    <h1>Todos:</h1>
    <ul>{{ list }}</ul>
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
  * Controller
  * ListController
  * Handlebars extensions
* Make ListController re-rendering more efficient
  * Pushing, unshifting, shifting, popping
  * Sorting, reversing
* Some sort of pluggable persistance backend
  * RESTful, WebSockets, LocalStorage, etc.
  * Should make it easy to define your own and subclass them, especially for
    WebSockets if you want to implement your own message protocol.
* Form bindings
  * You should be able to make create / edit forms super easily and never
    have to worry about maintaining bindings / events
* Better model change bindings
  * Ember.js-style might be overly ambitious / heavy, but it's worth
    investigation

Other random crap:

    model.toggle( "done" )
    # sugar for:
    model.set( "done", !model.get( "done" ) )

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
