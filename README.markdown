Rickshaw
========

Rickshaw is small but full-featured client-side MVC framework using (and adhering to the idioms of)
MooTools for models and controllers and Handlebars for templating (views).

Here is a brief to-do list example, as is required by law:

**Model and List**

    Todo = new Rickshaw.Model()

General Philosophy
------------------

MooTools is great and boilerplate is bad.

To do
-----

(Roughly in order of importance)

* Specs for:
  * Controller
  * ListController
  * Metamorph extensions
  * Handlebars extensions
* Make ListController re-rendering more efficient
  * Pushing, unshifting, shifting, popping
  * Sorting, reversing
* Some sort of persistance backend
  * RESTful, WebSockets, LocalStorage, etc.
* Form bindings
* Better model change bindings
  * Ember.js-style might be overly ambitious, but it's worth investigation

Specs
-----

If you want to run the specs headlessly (warning: qt is fairly hefty):

    brew update
    brew install qt
    bundle install
    bundle exec evergreen run

Or if you don't want / need to run them headlessly:

    rm .evergreen
    bundle install --without headless
    bundle exec evergreen serve

(`.evergreen` simply has the config for headless specs. Removing that file will tell `evergreen`
to default to Selenium.)

Examples
--------

### RESTful persistence ###

(Note: this is currently broken)

    var Message = new Class({
      Extends: Rickshaw.Model,
      Implements: Rickshaw.Persistence.RestfulJSON,
    
      store: {
        url: "/messages/{id}"
      }
    });

### Custom model property accessors ###

    var User = new Rickshaw.Model({
      getName: function() {
        return this.data.firstName + " " + this.data.lastName;
      },

      setName: function(value) {
        var names = value.split(" ");
        this.set("firstName", names[0]);
        this.set("lastName", names[1]);
      }
    }

### Collections ###

Collections are Array subclasses that have lots of additional event-firing
hotness.

    var Messages = new Rickshaw.Collection({
      modelClass: Message
    });
    
    var myMessages = new Messages(msgA, msgB, msgC);
    myMessages.push(msgD);
    # onAdd event is fired.
    myMessages.set({ state: "read", flagged: false });
    # all messages are updated with the above properties.

### Controllers ###

Template:

    <div class="message">Dear {{name}}, {{content}}</div>
    {{ tag "button.delete[text='Delete']" }}
    {{ subController replyForm "div.reply-form" }}

Controller:

    var MessageController = new Rickshaw.Controller({
      templateName: "message",

      initialize: function(message) {
        this.replyForm = new MessageReplyController(message);
        this.parent(message);
      },

      events: {
        ".delete": function(e) {
          e.preventDefault();
          this.model.delete();
        }
    });

Contributors
------------

* Tyson Tate
* Casey Speer - Early contributions to the persistence layer.
