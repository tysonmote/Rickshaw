Rickshaw
========

Powerful client-side MVC framework based on MooTools and Handlebars.

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
