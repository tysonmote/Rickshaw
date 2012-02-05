# Rickshaw._BaseController
# ========================
#
# (Private) Forms the basis of all Rickshaw controllers.
#
# Events
# ------
#
#   * onBeforeRender(controller) - Fired before the controller is rendered.
#   * onAfterRender(controller) - Fired after the controller is rendered.
#
Rickshaw._BaseController = new Class({

  Implements: [Events]

  # Options
  # -------

  # Name of template used to render this controller. (Required)
  Template: ""

  # Auto-attached element events. Keyed by element selector. (Optional)
  Events: {}

  initialize: (element=null) ->
    Rickshaw.register( this )
    Rickshaw.addParentClass( this )
    @rendered = false
    @_metamorphs = [] # All render destinations
    @_delayedSubControllers = [] # Delayed render sub-controllers
    this._setupEvents()
    this.renderTo( element ) if element
    return this

  _setupEvents: ->
    # Pre-bind element events to this controller and store in `@_boundEvents`.
    controller = this
    @_boundEvents = {}
    Object.each @Events, (events, selector) =>
      @_boundEvents[selector] = {}
      Object.each events.__proto__, (fn, eventName) =>
        fn = controller[fn] if typeof fn is "string"
        # Bind event callback to controller
        @_boundEvents[selector][eventName] = (e) ->
          fn.apply( controller, [e, this] )

    # Auto-hookup any instance methods of the form "onFooBar" as events.
    Object.each this.__proto__, (fn, name) =>
      if match = name.match( /^on[A-Z][A-Za-z]+$/ )
        this.addEvent match[0], -> fn.apply this, arguments

  # Rendering
  # ---------

  # (Re-)render to all destinations. Fires "beforeRender" and "afterRender"
  # events. Returns true after everything has been rendered.
  render: ->
    return false unless this._preRender( @_metamorphs )
    html = this._html()
    @_metamorphs.each (morph) => this._renderMetamorph( morph, html, false )
    this._postRender()
    return true

  # Renders to the bottom of the given element. Other render destinations
  # (metamorphs) will not be re-rendered.
  #
  # TODO: Accept other Metamorphs? Relative location argument?
  renderTo: (element) ->
    morph = new Rickshaw.Metamorph( this )
    @_metamorphs.push( morph )
    morph.inject( element )
    this._preRender( [morph] )
    this._renderMetamorph( morph )
    this._postRender()
    return true

  # Returns true if we should continue with rendering the given metamorphs.
  # Fires the "beforeRender" event.
  _preRender: (morphs) ->
    return false unless morphs.length > 0
    this.fireEvent "beforeRender", this
    return true

  # Render a single metamorph destination for this controller, as well as any
  # nested sub-controllers.
  _renderMetamorph: (morph, html=null) ->
    html ||= this._html()
    morph.setHTML( html )
    this._attachElementEvents( morph ) unless @_useRelayedEvents
    this._renderDelayedSubControllers()
    @rendered = true

  _postRender: ->
    this.fireEvent( "afterRender", this )

  _html: ->
    if template = Rickshaw.Templates[@Template]
      return template( this )
    else
      throw new Error "Template \"#{@Template}\" not found."

  # Subcontrollers
  # --------------

  # Creates a metamorph for the subcontroller, stores it in the subcontroller's
  # "_metamorphs" array, and returns the metamorph for the given subcontroller.
  # The subcontroller is added to this controllers list of subcontrollers to
  # render, if needed.
  #
  # If `useRelayedEvents` is true, the subcontroller will not attach element
  # events -- they should be taken care of as relayed events by a paret element
  # (esp. in ListController lists).
  _setupSubcontroller: (subcontroller, useRelayedEvents=false) ->
    # create and store the metamorph on the subcontroller
    morph = new Rickshaw.Metamorph( subcontroller )
    subcontroller._metamorphs.push( morph )
    subcontroller._useRelayedEvents = true if useRelayedEvents
    # render later
    @_delayedSubControllers.include( subcontroller )
    return morph

  _renderDelayedSubControllers: ->
    for controller in @_delayedSubControllers
      controller.render()
    @_delayedSubControllers = []

  # Element Events
  # --------------

  # Attach all element events to a given metamorph's elements.
  _attachElementEvents: (morph) ->
    Object.each @_boundEvents, (events, selector) ->
      morph.getElements( selector ).addEvents( events )

})

# Rickshaw.Controller
# ===================
#
# Render a single model using a template. Controllers can contain
# sub-controllers, rendered in-place with a `subController` Handlebar call in
# the template.
#
# Examples
# --------
#
# Basic:
#
#     # Template "user/greeting"
#     <p>Hello, {{ fullName }}!</p>
#     
#     # Controller
#     UserGreetingController = new Rickshaw.Controller({
#       Template: "user/greeting"
#       fullName: -> "#{@model.firstName} #{@model.firstName}"
#     })
#     controller = new UserRowController( user )
#     controller.renderTo( $( "user-greeting" ) )
#
# Sub-controllers:
#
#     # Template:
#     <p>Hello, {{ firstName }}! {{ subController logoutFormController }}</p>
#     
#     # Controller
#     UserGreetingController = new Rickshaw.Controller({
#       Template: "user/greeting"
#       initialize: (user) ->
#         @logoutFormController = new LogoutFormController( user )
#         this.parent( user )
#     })
#     controller = new UserRowController( user )
#     controller.renderTo( $( "user-greeting" ) )
#
Rickshaw._Controller = new Class({

  Extends: Rickshaw._BaseController

  # Attached model instance. This is set when this controller is created.
  model: null

  # An array of model property strings that will be created as simple defer
  # methods on this controller that return the value of the property.
  DeferToModel: []

  # Params:
  #
  #   * `model` (Rickshaw.Model) - Associated model.
  #   * `element` (Element, Elements, String, null) - DOM element, elements,
  #     or element id that this controller's rendered template HTML is rendered
  #     to. If this is null, it can be set to an Element or Elements later (as
  #     in the case of subController).
  initialize: (model=null, element=null) ->
    this.setModel( model, false ) if model
    this.parent( element )

  # Sets this controller's associated model instance and re-renders all
  # Metamorphs.
  setModel: (model, render=true) ->
    this._detachModelEvents( @model ) if @model
    @model = model
    this._setupModelDefers( @model )
    this._attachModelEvents( @model )
    this.render() if render
    return this

  _setupModelDefers: (model) ->
    @DeferToModel.each (property) =>
      this[property] = -> model.get( property )

  _attachModelEvents: (model) ->
    model.addEvent( "change", this._modelChanged )

  _detachModelEvents: (model) ->
    model.removeEvent( "change", this._modelChanged )

  # Hooks
  # -----

  # Bound to the controller instance.
  _modelChanged: (model, changedProperties) ->
    this.render() if @rendered

  # TODO: Re-implement model delete / destroy events.

  Binds: ["_modelChanged"]

})

Rickshaw.Controller = Rickshaw.Utils.subclassConstructor( Rickshaw._Controller )

# Rickshaw.ListController
# -----------------------
#
# Render a Rickshaw.List.
#
Rickshaw._ListController = new Class({

  Extends: Rickshaw._BaseController

  # Attached Rickshaw.List instance. This is optionally set when this
  # controller is created.
  collection: null

  # Either a Rickshaw.Controller class or a function that takes a model
  # instance and returns the correct controller class for that model.
  Subcontroller: ->
    throw new Error "Subcontroller not set for this ListController."

  # Params:
  #
  #   * `collection` (Rickshaw.List) - Associated collection of model
  #     elements to be rendered.
  #   * `element` (Element, Elements, String, null) - DOM element, elements,
  #     or element id that this controller's rendered template HTML is rendered
  #     to. If this is null, it can be set to an Element or Elements later (as
  #     in the case of the `subController` or `list` Handlebars helpers).
  initialize: (collection=null, element=null) ->
    this.setList( collection, false ) if collection
    # Selector for list container element. This is used for attaching relay
    # events for our list item sub-controllers (via _listWrapper()) and fast
    # list item insertion (unshift, push, append, etc)
    @_listWrapperSelector = null
    @_listMetamorph = null # TODO: remove?
    # Keep track of the sub-controller controller classes that we have already
    # set up relay events for.
    @_hasRelayedEvents = {}
    this.parent( element )

  # Sets this controller's associated collection instance and re-renders all
  # Metamorphs.
  setList: (collection, render=true) ->
    this._detachListEvents( @collection ) if @collection
    @collection = collection
    this._attachListEvents( @collection )
    this.render() if render

  # Subcontrollers
  # --------------

  # Creates subcontroller for the model and hooks it all up. Returns
  # a Rickshaw.Metamorph.
  _setupListItemController: (model) ->
    klass = if instanceOf( @Subcontroller, Class )
      @Subcontroller
    else
      this.Subcontroller( model )
    return this._setupSubcontroller( new klass( model ), true )

  # (Overrides parent class method.)
  _renderDelayedSubControllers: ->
    for controller in @_delayedSubControllers
      controller.render()
      this._setupSubcontrollerEventRelays( controller )
    @_delayedSubControllers = []

  # Get the list wrapper element that wraps this controller's list elements.
  _listWrapper: ->
    @__listWrapper ||= $$( @_listWrapperSelector )[0]

  # Given a controller instance, hook up relay events on the list wrapper so
  # that events don't have to be attached to every single list item's elements.
  # If the controller class's events have already been hooked up, we don't have
  # to do anything here.
  _setupSubcontrollerEventRelays: (controller) ->
    controllerClass = controller._class
    controllerClassUuid = controllerClass.$uuid
    return if @_hasRelayedEvents[controllerClassUuid]

    listWrapper = this._listWrapper()
    Object.each controllerClass.prototype.Events, (events, selector) ->
      Object.each events, (fn, type) ->
        listWrapper.addEvent "#{type}:relay(#{selector})", (e, target) ->
          eventFn = controllerClass::Events[selector][type]
          eventFn = controllerClass::[eventFn] if typeof eventFn is "string"
          unless eventFn
            throw new Error "Lost track of relayed event -- was it removed from the controller class?"
          controller = Rickshaw.Utils.findController( target, eventFn, selector, type )
          eventFn.apply( controller, [e, target] ) # Fire the event.

    @_hasRelayedEvents[controllerClassUuid] = true

  # Events
  # ------

  # Hook up the collection's events.
  _attachListEvents: (collection) ->
    collection.addEvents(
      add: this._modelsAdded
      remove: this._modelsRemoved
      sort: this._collectionSorted
      change: this._modelChanged
    )

  # Detach a collection's events.
  _detachListEvents: (collection) ->
    collection.removeEvents(
      add: this._modelsAdded
      remove: this._modelsRemoved
      sort: this._collectionSorted
      change: this._modelChanged
    )

  # Hooks
  # -----

  # TODO: So. The big trick here is going to be figuring out how to do the
  # minimum possible for each hook. When a model is appended, we should only be
  # appending the HTML and hooking up the events for that new HTML instead of
  # re-rendering the whole damn thing. When a model is removed, we should only
  # be removing those elements / sub-controllers. When the collection's
  # sort-order changes, we should figure out how to do the minimum
  # DOM-manipulation possible.

  # TODO: Refactor.
  _modelsAdded: (collection, models, position="unknown") ->
    return unless @rendered and models.length > 0

    listWrapper = this._listWrapper()
    unless listWrapper
      throw new Error "Template \"#{@Template}\" doesn't have a `{{ list }}` placeholder."

    if position is "end"
      models.each (model) =>
        morph = this._setupListItemController( model )
        morph.inject( listWrapper, "bottom" )
      this._renderDelayedSubControllers()
    else if position is "beginning"
      models.reverse().each (model) =>
        morph = this._setupListItemController( model )
        morph.inject( listWrapper, "top" )
      this._renderDelayedSubControllers()
    else
      this.render()

  _modelsRemoved: (collection, models, position="unknown") ->
    this.render() if @rendered

  _collectionSorted: ->
    this.render() if @rendered

  _modelChanged: (model, properties) ->
    # The model's `Rickshaw.Controller` instace will re-render itself. Don't
    # know if we actually need to do anything here until we implement filtering
    # on ListControllers.

  Binds: ["_modelsAdded", "_modelsRemoved", "_collectionSorted", "_modelChanged"]

})

Rickshaw.ListController = Rickshaw.Utils.subclassConstructor( Rickshaw._ListController )
