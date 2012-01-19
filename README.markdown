Rickshaw
========

Powerful client-side MVC framework based on MooTools for powerful OOP / MVC
and Handlebars for awesome templating.

Specs
-----

If you want to run the specs headlessly (warning: qt is pretty hefty):

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

To do
-----

(Roughly in order of importance)

* Get a spec suite up and running
* Make ListController rendering more efficient
* Add the persistance framework back

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
* Casey Speer - Early contributions to the persistance layer.
