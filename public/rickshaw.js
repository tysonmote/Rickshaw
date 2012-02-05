(function() {
  var _this = this,
    __slice = Array.prototype.slice;

  window.Rickshaw = {
    toString: function() {
      return "<Rickshaw global>";
    },
    version: "0.0.1",
    Templates: {},
    _objects: {},
    templatePrefix: "Rickshaw",
    templateRegex: /^Rickshaw-(\w+)-template$/,
    refreshTemplates: function(idRegex) {
      if (idRegex == null) idRegex = Rickshaw.templateRegex;
      Rickshaw.Templates || (Rickshaw.Templates = {});
      $$("script[id^='" + Rickshaw.templatePrefix + "']").each(function(el) {
        var name, parsedId;
        if (parsedId = idRegex.exec(el.get("id"))) {
          name = parsedId.getLast();
          return Rickshaw.Templates[name] = Handlebars.compile(el.get("html"));
        }
      });
      return Rickshaw.Templates;
    },
    _uuidCounter: 0,
    uuid: function() {
      return "rickshaw-" + (Rickshaw._uuidCounter++);
    },
    register: function(object) {
      object.$uuid = Rickshaw.uuid();
      return Rickshaw._objects[object.$uuid] = object;
    },
    addParentClass: function(object) {
      var uuid;
      if (!(uuid = object.$constructor.$uuid)) {
        throw new Error("The given object (" + (object.toString()) + ") doesn't have a parent Class with a UUID.");
      }
      return object._class = Rickshaw.get(uuid);
    },
    get: function(uuid) {
      return this._objects[uuid];
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
      return function(params) {
        var constructor;
        constructor = new Class(Object.merge({
          Extends: baseClass
        }, params));
        Rickshaw.register(constructor);
        return constructor;
      };
    },
    isModelInstance: function(item) {
      return !!(item.$uuid && item._get && item._set && item.data);
    },
    findController: function(element, eventFn, eventSelector, eventType) {
      var cursor, findPreviousMetamorphStart, isMatchingMetamorph;
      isMatchingMetamorph = function(element) {
        var controller, controllerFn, _ref, _ref2;
        if (!(element.tagName === "SCRIPT" && ((_ref = element.id) != null ? _ref.match(/^metamorph-\d+-start$/) : void 0))) {
          return false;
        }
        controller = element.retrieve("rickshaw-controller");
        if (!controller) return false;
        controllerFn = (_ref2 = controller.Events[eventSelector]) != null ? _ref2[eventType] : void 0;
        if (typeof controllerFn === "string") {
          controllerFn = controller[controllerFn];
        }
        return controllerFn === eventFn;
      };
      findPreviousMetamorphStart = function(element) {
        var parent, previous;
        if (previous = element.getPrevious("script[type='text/x-placeholder']")) {
          return previous;
        } else if (parent = element.getParent()) {
          if (parent === document.body) return parent;
          while (!(parent === document.body || (previous = parent.getPrevious("script[type='text/x-placeholder']")))) {
            parent = parent.getParent();
          }
          if (parent === document.body) {
            return document.body;
          } else {
            return previous;
          }
        } else {
          return document.body;
        }
      };
      cursor = element;
      while (!(cursor === document.body || isMatchingMetamorph(cursor))) {
        cursor = findPreviousMetamorphStart(cursor);
      }
      if (cursor === document.body) {
        throw new Error("findController() reached <body> without finding a matching metamorph.");
      } else {
        return cursor.retrieve("rickshaw-controller");
      }
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
    Defaults: {},
    initialize: function(data) {
      if (data == null) data = {};
      Rickshaw.register(this);
      this._initData(data);
      this._attachEvents();
      return this;
    },
    toString: function() {
      return "<Model " + this.$uuid + ">";
    },
    _initData: function(data) {
      var defaults;
      defaults = Object.map(this.__proto__.Defaults, function(value, key) {
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
      Object.each(this.__proto__, function(fn, name) {
        var event, match;
        if (match = name.match(/^on([A-Z])([A-Za-z]+Change)$/)) {
          event = match[1].toLowerCase() + match[2];
          return _this.addEvent(event, function() {
            return fn.apply(this, arguments);
          });
        }
      });
      if (this.__proto__.onChange) {
        return this.addEvent("change", function() {
          return this.__proto__.onChange.apply(this, arguments);
        });
      }
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
        return customGetter.bind(this)();
      } else {
        return this.data[property];
      }
    },
    set: function(property, value) {
      var changedProperties, newData,
        _this = this;
      if (typeOf(property) === "object") {
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
    toggle: function(property) {
      return this.set(property, !this.get(property));
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

  window.Model = Rickshaw.Utils.subclassConstructor(Rickshaw._Model);

  Rickshaw._List = new Class({
    Extends: Array,
    Implements: [Events],
    ModelClass: function() {
      throw new Error("No ModelClass has been defined for this List");
    },
    initialize: function() {
      Rickshaw.register(this);
      if (arguments.length > 0) this.push.apply(this, arguments);
      return this;
    },
    toString: function() {
      return "<List " + this.$uuid + ">";
    },
    uuids: function() {
      return this.mapProperty("$uuid");
    },
    push: function() {
      var models, result;
      models = this._prepareAddArgs(arguments);
      result = Array.prototype.push.apply(this, models);
      this.fireEvent("add", [this, models, "end"]);
      return result;
    },
    unshift: function() {
      var models, result;
      models = this._prepareAddArgs(arguments);
      result = Array.prototype.unshift.apply(this, models);
      this.fireEvent("add", [this, models, "beginning"]);
      return result;
    },
    include: function(model) {
      if (!this.contains(model)) this.push(model);
      return this;
    },
    combine: function(models) {
      var addedModels, model, _i, _len;
      models = this._prepareAddArgs(models);
      addedModels = [];
      for (_i = 0, _len = models.length; _i < _len; _i++) {
        model = models[_i];
        if (!this.contains(model)) {
          Array.prototype.push.apply(this, [model]);
          addedModels.push(model);
        }
      }
      if (addedModels.length > 0) {
        this.fireEvent("add", [this, addedModels, "end"]);
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
    shift: function() {
      var model;
      model = Array.prototype.shift.apply(this);
      this._detachModel(model);
      this.fireEvent("remove", [this, [model], "beginning"]);
      return model;
    },
    erase: function(model) {
      var i, removedIndexes;
      if (!Rickshaw.Utils.isModelInstance(model)) {
        throw new Error("Can't erase non-model objects yet.");
      }
      i = this.length;
      removedIndexes = [];
      while (i--) {
        if (this[i] === model) {
          removedIndexes.push(i);
          Array.prototype.splice.apply(this, [i, 1]);
        }
      }
      if (removedIndexes.length > 0) {
        this._detachModel(model);
        this.fireEvent("remove", [this, [model], removedIndexes]);
      }
      return this;
    },
    empty: function() {
      var removedModels;
      if (this.length === 0) return;
      this.each(this._detachModel);
      removedModels = this.map(function(obj) {
        return obj;
      });
      this.length = 0;
      this.fireEvent("remove", [this, removedModels, "all"]);
      return this;
    },
    splice: function() {
      var addModels, count, index, removedModels;
      index = arguments[0], count = arguments[1], addModels = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      removedModels = Array.prototype.splice.apply(this, [index, count]);
      removedModels.each(this._detachModel);
      if (removedModels.length > 0) {
        this.fireEvent("remove", [this, removedModels, index]);
      }
      if (addModels.length > 0) {
        addModels = this._prepareAddArgs(addModels);
        Array.prototype.splice.apply(this, [index, 0].concat(addModels));
        this.fireEvent("add", [this, addModels, index]);
      }
      return removedModels;
    },
    _detachModel: function(model) {
      model.removeEvent("change", this._modelChanged);
      return model.removeEvent("delete", this._modelDeleted);
    },
    sort: function(fnOrProp, direction) {
      var endOrder, startOrder;
      if (direction == null) direction = "ascending";
      startOrder = this.uuids();
      if (typeof fnOrProp === "function") {
        this.parent(fnOrProp);
      } else if (typeof fnOrProp === "string") {
        if (direction === "descending") {
          this.parent(function(a, b) {
            return Array._compare(b.get(fnOrProp), a.get(fnOrProp));
          });
        } else {
          this.parent(function(a, b) {
            return Array._compare(a.get(fnOrProp), b.get(fnOrProp));
          });
        }
      } else {
        throw new Error("You must pass a model property as a string or a sort function.");
      }
      endOrder = this.uuids();
      if (!Array._equal(startOrder, endOrder)) this.fireEvent("sort", [this]);
      return this;
    },
    _sortWithFn: function(fn) {
      return Array.prototype.sort.pass(this, [fn]);
    },
    reverse: function() {
      if (this.length < 2) return this;
      Array.prototype.reverse.apply(this);
      return this.fireEvent("sort", [this, "reverse"]);
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
      if (Rickshaw.Utils.isModelInstance(data)) {
        return data;
      } else {
        if (typeOf(this.ModelClass) === "function") {
          klass = this.ModelClass(data);
          return new klass(data);
        } else {
          return new this.ModelClass(data);
        }
      }
    },
    Binds: ["_modelChanged", "_modelDeleted", "_preattachModel", "_detachModel"]
  });

  window.List = Rickshaw.Utils.subclassConstructor(Rickshaw._List);

  Rickshaw._BaseController = new Class({
    Implements: [Events],
    Template: "",
    Events: {},
    initialize: function(element) {
      if (element == null) element = null;
      Rickshaw.register(this);
      Rickshaw.addParentClass(this);
      this.rendered = false;
      this._metamorphs = [];
      this._delayedSubControllers = [];
      this._setupEvents();
      if (element) this.renderTo(element);
      return this;
    },
    _setupEvents: function() {
      var controller,
        _this = this;
      controller = this;
      this._boundEvents = {};
      Object.each(this.Events, function(events, selector) {
        _this._boundEvents[selector] = {};
        return Object.each(events.__proto__, function(fn, eventName) {
          if (typeof fn === "string") fn = controller[fn];
          return _this._boundEvents[selector][eventName] = function(e) {
            return fn.apply(controller, [e, this]);
          };
        });
      });
      return Object.each(this.__proto__, function(fn, name) {
        var match;
        if (match = name.match(/^on[A-Z][A-Za-z]+$/)) {
          return _this.addEvent(match[0], function() {
            return fn.apply(this, arguments);
          });
        }
      });
    },
    render: function() {
      var html,
        _this = this;
      if (!this._preRender(this._metamorphs)) return false;
      html = this._html();
      this._metamorphs.each(function(morph) {
        return _this._renderMetamorph(morph, html, false);
      });
      this._postRender();
      return true;
    },
    renderTo: function(element) {
      var morph;
      morph = new Rickshaw.Metamorph(this);
      this._metamorphs.push(morph);
      morph.inject(element);
      this._preRender([morph]);
      this._renderMetamorph(morph);
      this._postRender();
      return true;
    },
    _preRender: function(morphs) {
      if (!(morphs.length > 0)) return false;
      this.fireEvent("beforeRender", this);
      return true;
    },
    _renderMetamorph: function(morph, html) {
      if (html == null) html = null;
      html || (html = this._html());
      morph.setHTML(html);
      if (!this._useRelayedEvents) this._attachElementEvents(morph);
      this._renderDelayedSubControllers();
      return this.rendered = true;
    },
    _postRender: function() {
      return this.fireEvent("afterRender", this);
    },
    _html: function() {
      var template;
      if (template = Rickshaw.Templates[this.Template]) {
        return template(this);
      } else {
        throw new Error("Template \"" + this.Template + "\" not found.");
      }
    },
    _setupSubcontroller: function(subcontroller, useRelayedEvents) {
      var morph;
      if (useRelayedEvents == null) useRelayedEvents = false;
      morph = new Rickshaw.Metamorph(subcontroller);
      subcontroller._metamorphs.push(morph);
      if (useRelayedEvents) subcontroller._useRelayedEvents = true;
      this._delayedSubControllers.include(subcontroller);
      return morph;
    },
    _renderDelayedSubControllers: function() {
      var controller, _i, _len, _ref;
      _ref = this._delayedSubControllers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        controller = _ref[_i];
        controller.render();
      }
      return this._delayedSubControllers = [];
    },
    _attachElementEvents: function(morph) {
      return Object.each(this._boundEvents, function(events, selector) {
        return morph.getElements(selector).addEvents(events);
      });
    }
  });

  Rickshaw._Controller = new Class({
    Extends: Rickshaw._BaseController,
    model: null,
    DeferToModel: [],
    initialize: function(model, element) {
      if (model == null) model = null;
      if (element == null) element = null;
      if (model) this.setModel(model, false);
      return this.parent(element);
    },
    toString: function() {
      return "<Controller " + this.$uuid + ">";
    },
    setModel: function(model, render) {
      if (render == null) render = true;
      if (this.model) this._detachModelEvents(this.model);
      this.model = model;
      this._setupModelDefers(this.model);
      this._attachModelEvents(this.model);
      if (render) this.render();
      return this;
    },
    _setupModelDefers: function(model) {
      var _this = this;
      return this.DeferToModel.each(function(property) {
        return _this[property] = function() {
          return model.get(property);
        };
      });
    },
    _attachModelEvents: function(model) {
      return model.addEvent("change", this._modelChanged);
    },
    _detachModelEvents: function(model) {
      return model.removeEvent("change", this._modelChanged);
    },
    _modelChanged: function(model, changedProperties) {
      if (this.rendered) return this.render();
    },
    Binds: ["_modelChanged"]
  });

  window.Controller = Rickshaw.Utils.subclassConstructor(Rickshaw._Controller);

  Rickshaw._ListController = new Class({
    Extends: Rickshaw._BaseController,
    collection: null,
    Subcontroller: function() {
      throw new Error("Subcontroller not set for this ListController.");
    },
    initialize: function(collection, element) {
      if (collection == null) collection = null;
      if (element == null) element = null;
      if (collection) this.setList(collection, false);
      this._listWrapperSelector = null;
      this._listMetamorph = null;
      this._hasRelayedEvents = {};
      return this.parent(element);
    },
    toString: function() {
      return "<ListController " + this.$uuid + ">";
    },
    setList: function(collection, render) {
      if (render == null) render = true;
      if (this.collection) this._detachListEvents(this.collection);
      this.collection = collection;
      this._attachListEvents(this.collection);
      if (render) return this.render();
    },
    _setupListItemController: function(model) {
      var klass;
      klass = instanceOf(this.Subcontroller, Class) ? this.Subcontroller : this.Subcontroller(model);
      return this._setupSubcontroller(new klass(model), true);
    },
    _renderDelayedSubControllers: function() {
      var controller, _i, _len, _ref;
      _ref = this._delayedSubControllers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        controller = _ref[_i];
        controller.render();
        this._setupSubcontrollerEventRelays(controller);
      }
      return this._delayedSubControllers = [];
    },
    _listWrapper: function() {
      return this.__listWrapper || (this.__listWrapper = $$(this._listWrapperSelector)[0]);
    },
    _setupSubcontrollerEventRelays: function(controller) {
      var controllerClass, controllerClassUuid, listWrapper;
      controllerClass = controller._class;
      controllerClassUuid = controllerClass.$uuid;
      if (this._hasRelayedEvents[controllerClassUuid]) return;
      listWrapper = this._listWrapper();
      Object.each(controllerClass.prototype.Events, function(events, selector) {
        return Object.each(events, function(fn, type) {
          return listWrapper.addEvent("" + type + ":relay(" + selector + ")", function(e, target) {
            var eventFn;
            eventFn = controllerClass.prototype.Events[selector][type];
            if (typeof eventFn === "string") {
              eventFn = controllerClass.prototype[eventFn];
            }
            if (!eventFn) {
              throw new Error("Lost track of relayed event -- was it removed from the controller class?");
            }
            controller = Rickshaw.Utils.findController(target, eventFn, selector, type);
            return eventFn.apply(controller, [e, target]);
          });
        });
      });
      return this._hasRelayedEvents[controllerClassUuid] = true;
    },
    _attachListEvents: function(collection) {
      return collection.addEvents({
        add: this._modelsAdded,
        remove: this._modelsRemoved,
        sort: this._collectionSorted,
        change: this._modelChanged
      });
    },
    _detachListEvents: function(collection) {
      return collection.removeEvents({
        add: this._modelsAdded,
        remove: this._modelsRemoved,
        sort: this._collectionSorted,
        change: this._modelChanged
      });
    },
    _modelsAdded: function(collection, models, position) {
      var listMetamorph, listWrapper,
        _this = this;
      if (position == null) position = "unknown";
      if (!(this.rendered && models.length > 0)) return;
      listWrapper = this._listWrapper();
      if (!listWrapper) {
        throw new Error("Template \"" + this.Template + "\" doesn't have a `{{ list }}` placeholder.");
      }
      listMetamorph = this._listMetamorph;
      if (position === "end") {
        models.each(function(model) {
          var morph;
          morph = _this._setupListItemController(model);
          return morph.inject(listMetamorph.endMarkerElement(), "before");
        });
        return this._renderDelayedSubControllers();
      } else if (position === "beginning") {
        models.reverse().each(function(model) {
          var morph;
          morph = _this._setupListItemController(model);
          return morph.inject(listWrapper, "top");
        });
        return this._renderDelayedSubControllers();
      } else {
        return this.render();
      }
    },
    _modelsRemoved: function(collection, models, position) {
      if (position == null) position = "unknown";
      if (this.rendered) return this.render();
    },
    _collectionSorted: function() {
      if (this.rendered) return this.render();
    },
    _modelChanged: function(model, properties) {},
    Binds: ["_modelsAdded", "_modelsRemoved", "_collectionSorted", "_modelChanged"]
  });

  window.ListController = Rickshaw.Utils.subclassConstructor(Rickshaw._ListController);

  Handlebars.registerHelper("subController", function(controller, options) {
    var morph;
    if (arguments.length !== 2) {
      throw new Error("You must supply a controller instance to \"subController\".");
    }
    if (!controller) {
      throw new Error("Invalid controller passed to the subController template helper.");
    }
    morph = this._setupSubcontroller(controller);
    return new Handlebars.SafeString(morph.outerHTML());
  });

  Handlebars.registerHelper("tag", function(tag, options) {
    return new Handlebars.SafeString((new Element(tag)).outerHTML);
  });

  Handlebars.registerHelper("list", function(wrapperSelector, options) {
    var html, splitWrapperTag,
      _this = this;
    if (typeOf(this.collection) !== "array") {
      throw new Error("You can only use the \"list\" Handlebars helper in a ListController template.");
    }
    if (!options) {
      options = wrapperSelector;
      wrapperSelector = "div";
    }
    if (wrapperSelector.match(/#\w|\[id=/)) {
      wrapperSelector += "[data-uuid='" + (Rickshaw.uuid()) + "']";
    } else {
      wrapperSelector += "#" + (Rickshaw.uuid());
    }
    this._listWrapperSelector = wrapperSelector;
    splitWrapperTag = (new Element(wrapperSelector)).outerHTML.match(/(<\w+[^>]+>)(<\/\w+>)/);
    this._listMetamorph = new Rickshaw.Metamorph(this);
    html = [];
    html.push(splitWrapperTag[1]);
    html.push(this._listMetamorph.startMarkerTag());
    this.collection.each(function(model) {
      return html.push(_this._setupListItemController(model).outerHTML());
    });
    html.push(this._listMetamorph.endMarkerTag());
    html.push(splitWrapperTag[2]);
    return new Handlebars.SafeString(html.join(""));
  });

  Rickshaw.Metamorph = new Class({
    initialize: function(controller, html) {
      this.controller = controller;
      if (html == null) html = "";
      Rickshaw.register(this);
      this._morph = Metamorph(html);
      return this;
    },
    toString: function() {
      return "<Rickshaw.Metamorph " + this.$uuid + ">";
    },
    inject: function(element, position) {
      var firstChild;
      if (position == null) position = "bottom";
      element = $(element);
      if (position === "top") {
        if (firstChild = element.getElement("*")) {
          this._injectBefore(firstChild);
        } else {
          this._morph.appendTo(element);
        }
      } else if (position === "before") {
        this._injectBefore(element);
      } else if (position === "after") {
        this._injectAfter(element);
      } else if (position === "bottom") {
        this._morph.appendTo(element);
      } else {
        throw new Error("\"" + position + "\" is not a valid metamorph inject position.");
      }
      this.startMarkerElement().store("rickshaw-controller", this.controller);
      return this;
    },
    _injectAfter: function(element) {
      return this._rangedInject(element, "setStartAfter", "setEndAfter");
    },
    _injectBefore: function(element) {
      return this._rangedInject(element, "setStartBefore", "setEndBefore");
    },
    _rangedInject: function(element, startMethod, endMethod) {
      var fragment, range;
      range = document.createRange();
      range[startMethod](element);
      range[endMethod](element);
      fragment = range.createContextualFragment(this._morph.outerHTML());
      return range.insertNode(fragment);
    },
    setHTML: function(html) {
      this._morph.html(html);
      return this.startMarkerElement().store("rickshaw-controller", this.controller);
    },
    outerHTML: function() {
      return this._morph.outerHTML();
    },
    startMarkerTag: function() {
      return this._morph.startTag();
    },
    startMarkerElement: function() {
      return this._startMarkerElement || (this._startMarkerElement = $(this._morph.start));
    },
    endMarkerTag: function() {
      return this._morph.endTag();
    },
    endMarkerElement: function() {
      return this._endMarkerElement || (this._endMarkerElement = $(this._morph.end));
    },
    rootElements: function() {
      var el, i, idMatch, nextElements, rootElements, seekEndId, selfIndex, start, _len;
      if (!(start = this.startMarkerElement())) {
        throw new Error("This Metamorph hasn't been inserted into the DOM yet.");
      }
      rootElements = new Elements();
      selfIndex = parseInt(this._morph.start.match(/\d+/));
      nextElements = start.getAllNext("*:not(#metamorph-" + selfIndex + "-end)");
      for (i = 0, _len = nextElements.length; i < _len; i++) {
        el = nextElements[i];
        if (el.tagName === "SCRIPT" && el.id && (idMatch = el.id.match(/^metamorph-(\d+)-start/))) {
          seekEndId = "metamorph-" + idMatch[1] + "-end";
          i = i + 1;
          while (el = nextElements[i] && !(el.tagName === "SCRIPT" && el.id === seekEndId)) {
            i = i + 1;
          }
        } else {
          rootElements.push(el);
        }
      }
      return rootElements;
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
