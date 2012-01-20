(function() {
  var _this = this,
    __slice = Array.prototype.slice;

  window.Rickshaw = {
    version: "0.0.1",
    Templates: {},
    Persistence: {},
    _objects: {},
    templatePrefix: "Rickshaw",
    templateRegex: /^Rickshaw-(\w+)-template$/,
    refreshTemplates: function(idRegex) {
      idRegex || (idRegex = this.templateRegex);
      Rickshaw.Templates || (Rickshaw.Templates = {});
      $$("script[id^='" + this.templatePrefix + "']").each(function(el) {
        var name, parsedId;
        if (parsedId = idRegex.exec(el.get("id"))) {
          name = parsedId.getLast();
          return Rickshaw.Templates[name] = Handlebars.compile(el.get("html"));
        }
      });
      return Rickshaw.Templates;
    },
    uuid: function() {
      var i, str;
      str = ["rickshaw-"];
      i = 0;
      while (i++ < 17) {
        str.push(i !== 9 ? Math.round(Math.random() * 15).toString(16) : "-");
      }
      return str.join("");
    },
    register: function(object) {
      object._uuid = Rickshaw.uuid();
      return Rickshaw._objects[object._uuid] = object;
    },
    get: function(uuid) {
      return this._objects[uuid];
    },
    DELETE: function(object) {
      return delete Rickshaw._objects[object._uuid];
    }
  };

  document.addEvent("domready", Rickshaw.refreshTemplates);

  Rickshaw.Utils = {
    clone: function(item) {
      switch (typeOf(item)) {
        case "array":
          return item.clone();
        case "object":
          return Object.clone(item);
        default:
          return item;
      }
    },
    equal: function(a, b) {
      var aType;
      aType = typeOf(a);
      if (aType !== typeOf(b)) return false;
      if (aType === "array") {
        return Array._equal(a, b);
      } else if (aType === "object") {
        return Object._equal(a, b);
      } else {
        return a === b;
      }
    },
    subclassConstructor: function(baseClass) {
      return (function(params) {
        return new Class(Object.merge({
          Extends: baseClass
        }, params));
      });
    }
  };

  Array.extend({
    _equal: function(arrayA, arrayB) {
      var _ref;
      if (("array" !== (_ref = typeOf(arrayA)) || _ref !== typeOf(arrayB))) {
        return false;
      }
      if (arrayA.length !== arrayB.length) return false;
      return arrayA.every(function(value, index) {
        switch (typeOf(value)) {
          case "object":
            return Object._equal(value, arrayB[index]);
          case "array":
            return Array._equal(value, arrayB[index]);
          default:
            return value === arrayB[index];
        }
      });
    },
    _compare: function(a, b) {
      if (a < b) return -1;
      if (a === b) return 0;
      return 1;
    }
  });

  Array.implement({
    mapProperty: function(property) {
      return this.map(function(item) {
        return item[property];
      });
    }
  });

  Object.extend({
    _equal: function(objectA, objectB) {
      var _ref;
      if (("object" !== (_ref = typeOf(objectA)) || _ref !== typeOf(objectB))) {
        return false;
      }
      if (Object.keys(objectA).sort().join("") !== Object.keys(objectB).sort().join("")) {
        return false;
      }
      return Object.every(objectA, function(value, key) {
        switch (typeOf(value)) {
          case "object":
            return Object._equal(value, objectB[key]);
          case "array":
            return Array._equal(value, objectB[key]);
          default:
            return value === objectB[key];
        }
      });
    }
  });

  String.implement({
    forceCamelCase: function() {
      return String(this).replace(/[-_\s]\D/g, function(match) {
        return match.charAt(1).toUpperCase();
      });
    }
  });

  Class.Mutators.Binds = function(binds) {
    if (!this.prototype.initialize) this.implement("initialize", function() {});
    return Array.from(binds).concat(this.prototype.Binds || []);
  };

  Class.Mutators.initialize = function(initialize) {
    return (function() {
      Array.from(this.Binds).each((function(name) {
        var original;
        if (original = this[name]) return this[name] = original.bind(this);
      }), this);
      return initialize.apply(this, arguments);
    });
  };

  Rickshaw._Model = new Class({
    Implements: [Events],
    defaults: {},
    initialize: function(data) {
      if (data == null) data = {};
      Rickshaw.register(this);
      this._initData(data);
      this._attachEvents();
      return this;
    },
    _initData: function(data) {
      var defaults;
      this.defaults = Object.clone(this.defaults);
      defaults = Object.map(this.defaults, function(value, key) {
        if (typeof value === "function") {
          return value.apply(this, [this]);
        } else {
          return value;
        }
      });
      this.data = Object.merge(defaults, data);
      this._previousData = Object.clone(this.data);
      return this.dirtyProperties = [];
    },
    _attachEvents: function() {
      var _this = this;
      return Object.each(this.__proto__, function(fn, name) {
        var match;
        if (match = name.match(/^on[A-Z][A-Za-z]+Change$/)) {
          return _this.addEvent(match[0], function() {
            return fn.apply(this, arguments);
          });
        }
      });
    },
    isDirty: function() {
      return this.dirtyProperties.length > 0;
    },
    get: function() {
      var properties,
        _this = this;
      properties = Array.from(arguments).flatten();
      if (properties.length > 1) {
        return properties.map(function(property) {
          return _this._get(property);
        }).associate(properties);
      } else {
        return this._get(properties[0]);
      }
    },
    _get: function(property) {
      var customGetter;
      if (customGetter = this["get" + (property.forceCamelCase().capitalize())]) {
        return Rickshaw.Utils.clone(customGetter.bind(this)());
      } else {
        return Rickshaw.Utils.clone(this.data[property]);
      }
    },
    set: function(property, value) {
      var changedProperties, newData,
        _this = this;
      if (typeof property === "object") {
        newData = property;
      } else {
        newData = {};
        newData[property] = value;
      }
      changedProperties = [];
      Object.each(newData, function(newValue, property) {
        if (_this._set(property, newValue)) {
          return changedProperties.push(property);
        }
      });
      if (changedProperties.length > 0) {
        changedProperties.each(function(property) {
          return _this.fireEvent("" + (property.forceCamelCase()) + "Change", _this);
        });
        this.fireEvent("change", [this, changedProperties]);
      }
      return this;
    },
    _set: function(property, value) {
      var customSetter, newValue;
      newValue = Rickshaw.Utils.clone(value);
      if (customSetter = this["set" + (property.forceCamelCase().capitalize())]) {
        newValue = customSetter.apply(this, [newValue]);
      }
      if (Rickshaw.Utils.equal(this._previousData[property], newValue)) {
        this.dirtyProperties = this.dirtyProperties.erase(property);
      } else {
        this.dirtyProperties.include(property);
      }
      if (Rickshaw.Utils.equal(this.data[property], newValue)) {
        return false;
      } else {
        this.data[property] = newValue;
        return true;
      }
    },
    Binds: ["_get", "_set"]
  });

  Rickshaw.Model = Rickshaw.Utils.subclassConstructor(Rickshaw._Model);

  Rickshaw._List = new Class({
    Extends: Array,
    Implements: [Events],
    modelClass: Rickshaw.Model,
    models: [],
    initialize: function() {
      Rickshaw.register(this);
      if (arguments.length > 0) this._add("push", arguments);
      return this;
    },
    uuids: function() {
      return this.models.mapProperty("uuid");
    },
    push: function(model) {
      var models, result;
      models = this._prepareAddArgs(model);
      result = Array.prototype.push.apply(this, models);
      this.fireEvent("add", [this, models, "end"]);
      return result;
    },
    unshift: function(model) {
      var models, result;
      models = this._prepareAddArgs(model);
      result = Array.prototype.unshift.apply(this, models);
      this.fireEvent("add", [this, models, "beginning"]);
      return result;
    },
    include: function(model) {
      var models, startingLength;
      startingLength = this.length;
      models = this._prepareAddArgs(model);
      Array.prototype.push.apply(this, models);
      if (startingLength !== this.length) {
        this.fireEvent("add", [this, models, "beginning"]);
      }
      return this;
    },
    combine: function(models) {
      var newModels, startingLength;
      startingLength = this.length;
      models = this._prepareAddArgs(models);
      Array.prototype.combine.apply(this, models);
      if (startingLength !== this.length) {
        newModels = this.slice(startingLength);
        this.fireEvent("add", [this, newModels, "beginning"]);
      }
      return this;
    },
    _prepareAddArgs: function(args) {
      var models;
      models = this._ensureModels(Array.from(args).flatten());
      models.each(this._preattachModel);
      return models;
    },
    _preattachModel: function(model) {
      if (this.contains(model)) return false;
      return model.addEvents({
        change: this._modelChanged,
        "delete": this._modelDeleted
      });
    },
    pop: function() {
      var model;
      model = Array.prototype.pop.apply(this);
      this._detachModel(model);
      this.fireEvent("remove", [this, [model], "end"]);
      return model;
    },
    unshift: function() {
      var model;
      model = Array.prototype.unshift.apply(this);
      this._detachModel(model);
      this.fireEvent("remove", [this, [model], "beginning"]);
      return model;
    },
    erase: function(model) {
      var startingLength;
      if (!model._uuid) throw "Can't erase non-model objects yet.";
      startingLength = this.length;
      Array.prototype.erase.apply(this, model);
      if (startingLength !== this.length) {
        this._detachModel(model);
        this.fireEvent("remove", [this, [model]]);
      }
      return this;
    },
    empty: function() {
      if (this.length === 0) return;
      this.each(this._detachModel);
      this.fireEvent("remove", [this, this]);
      this.length = 0;
      return this;
    },
    splice: function() {
      var addModels, count, index, removedModels;
      index = arguments[0], count = arguments[1], addModels = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      removedModels = Array.prototype.splice.apply(this, arguments);
      removedModels.each(this._detachModel);
      if (removedModels.length > 0) {
        this.fireEvent("remove", [this, removedModels, index]);
      }
      if (addModels.length > 0) {
        addModels = this._prepareAddArgs(addModels);
        Array.prototype.splice.apply(this, [index, 0, addModels]);
        this.fireEvent("add", [this, addModels, index]);
      }
      return removedModels;
    },
    _detachModel: function(model) {
      model.removeEvent("change", this._modelChanged);
      return model.removeEvent("delete", this._modelDeleted);
    },
    sort: function(fn) {
      var endOrder, startOrder;
      startOrder = this.uuids();
      this.parent(fn);
      endOrder = this.uuids();
      if (!Array._equal(startOrder, endOrder)) {
        return this.fireEvent("sort", [this]);
      }
    },
    reverse: function() {
      if (this.length < 2) return this;
      Array.prototype.reverse.apply(this);
      return this.fireEvent("sort", [this]);
    },
    _modelChanged: function(model, properties) {
      return this.fireEvent("change", [this, model, properties]);
    },
    _modelDeleted: function(model) {
      model.removeEvent();
      return this.remove(model);
    },
    _ensureModels: function(array) {
      var _this = this;
      return Array.from(array).map(function(item) {
        if (typeOf(item) === "array") {
          return _this._ensureModels(item);
        } else {
          return _this._modelFrom(item);
        }
      });
    },
    _modelFrom: function(data) {
      var klass;
      if (typeOf(data) === "class") {
        return data;
      } else {
        if (typeOf(this.modelClass) === "function") {
          klass = this.modelClass(data);
          return new klass(data);
        } else {
          return new this.modelClass(data);
        }
      }
    },
    Binds: ["_modelChanged", "_modelDeleted", "_preattachModel", "_detachModel"]
  });

  Rickshaw.List = Rickshaw.Utils.subclassConstructor(Rickshaw._List);

  Rickshaw._BaseController = new Class({
    Implements: [Events],
    templateName: "",
    events: {},
    initialize: function(element, options) {
      if (element == null) element = null;
      if (options == null) options = {};
      Rickshaw.register(this);
      this._metamorphs = [];
      this._deferredSubControllers = [];
      this.events = Object.clone(this.events);
      if (element) this.renderTo(element);
      return this;
    },
    renderTo: function(element) {
      var morph;
      morph = new Rickshaw.Metamorph();
      this._metamorphs.push(morph);
      morph.inject(element);
      return this._renderMetamorph(morph);
    },
    render: function() {
      var html,
        _this = this;
      if (!(this._metamorphs.length > 0)) return;
      this.fireEvent("beforeRender", this);
      html = this._html();
      this._metamorphs.each(function(morph) {
        return _this._renderMetamorph(morph, html, false);
      });
      return this._finalizeRender();
    },
    _finalizeRender: function() {
      this._renderSubControllers();
      return this.fireEvent("afterRender", this);
    },
    _renderMetamorph: function(morph, html, fireEvent) {
      if (html == null) html = null;
      if (fireEvent == null) fireEvent = true;
      html || (html = this._html());
      morph.set("html", html);
      this._attachEvents(morph);
      this._renderSubControllers(morph);
      if (fireEvent) return this.fireEvent("afterRender", this);
    },
    _html: function() {
      var template;
      if (template = Rickshaw.Templates[this.templateName]) {
        return template(this);
      } else {
        throw "Template \"" + this.templateName + "\" not found.";
      }
    },
    _setupSubcontroller: function(subcontroller) {
      var morph;
      morph = new Rickshaw.Metamorph();
      subcontroller._metamorphs.push(morph);
      this._deferredSubControllers.include(subcontroller);
      return morph.outerHTML();
    },
    _renderSubControllers: function() {
      var controller, _results;
      _results = [];
      while (controller = this._deferredSubControllers.shift()) {
        _results.push(controller.render());
      }
      return _results;
    },
    _attachEvents: function(morph) {
      var _this = this;
      return Object.each(this._boundElementEvents(), function(events, selector) {
        return morph.getElements(selector).addEvents(events);
      });
    },
    _boundElementEvents: function() {
      var controller;
      if (this.__boundElementEvents) return this.__boundElementEvents;
      controller = this;
      return this.__boundElementEvents || (this.__boundElementEvents = Object.map(this.events, function(events, selector) {
        return Object.map(events, function(fn, eventName) {
          if (typeof fn === "string") fn = controller[fn];
          return function(e) {
            return fn.apply(controller, [e, this]);
          };
        });
      }));
    }
  });

  Rickshaw._Controller = new Class({
    Extends: Rickshaw._BaseController,
    model: null,
    initialize: function(model, element) {
      if (model == null) model = null;
      if (element == null) element = null;
      if (model) this.setModel(model, false);
      return this.parent(element);
    },
    setModel: function(model, render) {
      if (render == null) render = true;
      if (this.model) this._detachModelEvents(this.model);
      this.model = model;
      this._attachModelEvents(this.model);
      if (render) return this.render();
    },
    _attachModelEvents: function(model) {
      return model.addEvents({
        change: this._modelChanged,
        "delete": this._modelsDeleted
      });
    },
    _detachModelEvents: function(model) {
      return model.removeEvents({
        change: this._modelChanged,
        "delete": this._modelsDeleted
      });
    },
    _modelChanged: function(model, changedProperties) {
      return this.render();
    },
    _modelsDeleted: function() {
      return this._metamorphs.each(function(morph) {
        return morph.set("html", "");
      });
    },
    Binds: ["_modelChanged", "_modelsDeleted"]
  });

  Rickshaw.Controller = Rickshaw.Utils.subclassConstructor(Rickshaw._Controller);

  Rickshaw._ListController = new Class({
    Extends: Rickshaw._BaseController,
    collection: null,
    subcontroller: null,
    initialize: function(collection, element) {
      if (collection == null) collection = null;
      if (element == null) element = null;
      if (collection) this.setList(collection, false);
      return this.parent(element);
    },
    setList: function(collection, render) {
      if (render == null) render = true;
      if (this.collection) this._detachListEvents(this.collection);
      this.collection = collection;
      this._attachListEvents(this.collection);
      if (render) return this.render();
    },
    _setupSubcontrollerWithModel: function(model) {
      var klass;
      klass = typeof this.subcontroller === "function" ? this.subcontroller(model) : this.subcontroller;
      return this._setupSubcontroller(new klass(model));
    },
    _attachListEvents: function() {
      return this.collection.addEvents({
        add: this._modelsAdded,
        remove: this._modelsRemoved,
        sort: this._collectionSorted,
        change: this._modelChanged
      });
    },
    _detachListEvents: function() {
      return this.collection.removeEvents({
        add: this._modelsAdded,
        remove: this._modelsRemoved,
        sort: this._collectionSorted,
        change: this._modelChanged
      });
    },
    _modelsAdded: function(collection, models, position) {
      if (position == null) position = "unknown";
      console.log("_modelsAdded", arguments);
      return this.render();
    },
    _modelsRemoved: function(collection, models, position) {
      if (position == null) position = "unknown";
      console.log("_modelsRemoved", arguments);
      return this.render();
    },
    _collectionSorted: function() {
      console.log("_collectionSorted", arguments);
      return this.render();
    },
    _modelChanged: function(model, properties) {
      return console.log("_modelChanged", arguments);
    },
    Binds: ["_modelsAdded", "_modelsRemoved", "_collectionSorted", "_modelChanged"]
  });

  Rickshaw.ListController = Rickshaw.Utils.subclassConstructor(Rickshaw._ListController);

  Rickshaw.Metamorph = new Class({
    initialize: function(html) {
      if (html == null) html = "";
      Rickshaw.register(this);
      this._morph = Metamorph(html);
      return this;
    },
    inject: function(element) {
      return this._morph.appendTo($(element));
    },
    placeholderHTML: function() {
      return this._morph.startTag() + this._morph.endTag();
    },
    set: function(prop, value) {
      if (prop !== "html") {
        raise("Don't know how to set \"" + prop + "\" on Rickshaw.Metamorphs");
      }
      return this._morph.html(value);
    },
    outerHTML: function() {
      return this._morph.outerHTML();
    },
    _startElement: function() {
      return this.__startElement || (this.__startElement = $(this._morph.start));
    },
    rootElements: function() {
      var start;
      start = this._startElement();
      if (!start) raise("This Metamorph hasn't been inserted into the DOM yet.");
      return start.getAllNext("*:not(script[type='text/x-placeholder'])");
    },
    getElements: function(selector) {
      var matches, rootElements;
      rootElements = this.rootElements();
      matches = new Elements();
      matches.append(rootElements.filter(function(el) {
        return el.match(selector);
      }));
      matches.append(rootElements.getElements(selector).flatten());
      return matches;
    }
  });

}).call(this);
