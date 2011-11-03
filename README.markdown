Rickshaw
========

Rickshaw is an in-progress MooTools-based client-side MVC framework.

Examples
--------

### RESTful persistence ###

    var Message = new Class({
      Extends: Rickshaw.Model,
      Implements: Rickshaw.Persistence.RestfulJSON,
      
      store: {
        url: "/messages/{id}"
      }
    });

### Custom model property accessors ###

    var User = new Class({
      Extends: Rickshaw.Model,
      
      getters: {
        name: function() {
          return this.data.firstName + " " + this.data.lastName;
        }
      },
      
      setters: {
        name: function(value) {
          var names = value.split(" ");
          this.data.firstName = names[0];
          this.data.lastName = names[1];
        }
      }
    });

### Collections ###

    var Messages = new Class({
      Extends: Rickshaw.Collection,
      modelClass: Message
    });
    
    var myMessages = new Messages([msgA, msgB, msgC]);
    myMessages.append(msgD);
    myMessages.set({ state: "read", flagged: false });

### Controllers ###

    var MessageController = new Class({
      Extends: Rickshaw.Controller.Single,
      
      elementEvents: {
        ".delete": function(e) {
          e.stop();
          this.model.delete();
        }
    });

Contributors
------------

* Tyson Tate
* Casey Speer
