# Rickshaw._BaseController
# ========================
#
# (Private) Forms the basis of all Rickshaw controllers.
#
# Events
# ------
#
#   * onAfterRender(controller) - Fired after each view is rendered. Most
#     controllers will have only one view (aka render destination).
#
Rickshaw._BaseController = new Class({

  Implements: [Events]

  # Options
  # -------

  # Name of template used to render this controller. (Required)
  Template: ""

  # Auto-attached element events. Keyed by element selector. (Optional)
  Events: {}

  # Setup
  # -----

  initialize: (element, position="bottom") ->
    Rickshaw.addUuid( this )
    @rendered = false
    @views = []
    this._setupEvents()
    this.renderTo( element, position ) if element
    return this

  # Pre-bind element events to this controller and store in `@_boundEvents`.
  _setupEvents: ->
    controller = this
    @_boundEvents = {}

    for own selector, events of @Events
      @_boundEvents[selector] = {}
      for own type, fn of events.__proto__
        fn = this[fn] if typeof fn is "string"
        # Bind event callback to controller.
        boundFn = (e) ->
          view = Rickshaw.Metamorph.findView( this, boundFn, selector, type )
          fn.apply( controller, [e, this, view] )
        @_boundEvents[selector][type] = boundFn

    # Auto-hookup any instance methods of the form "onFooBar" as events.
    Object.each this.__proto__, (fn, name) =>
      if match = name.match( /^on[A-Z][A-Za-z]+$/ )
        controller.addEvent match[0], fn.bind( controller )

  # Rendering
  # ---------

  # (Re-)render all views or a single view.
  render: (view) ->
    if view
      view.render()
      this._attachElementEvents( view )
    else
      return false unless @views.length > 0
      this.render( view ) for view in @views
    @rendered = true
    return true

  # Render to a new destination. `postion` can be: top, bottom, above, or below.
  renderTo: (element, position="bottom") ->
    view = new View( this, @Template )
    view.addEvent( "afterRender", this._onAfterViewRender )
    @views.push( view )
    view.renderTo( element, position )
    this._attachElementEvents( view )
    @rendered = true
    return true

  # Render events
  # -------------

  _onAfterViewRender: (view) ->
    this.fireEvent( "afterRender", [this, view] )

  # Element Events
  # --------------

  # Attach all element events to a given metamorph's elements.
  _attachElementEvents: (view) ->
    view.addEvents( @_boundEvents )

  Binds: ["_onAfterViewRender"]

})

# Controller
# ==========
#
# Render a single model using a template. Views can contain other controllers
# (sub-controllers / sub-views), rendered in-place with a `subController`
# Handlebar call in the template.
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
#     UserGreetingController = new Controller({
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
#     UserGreetingController = new Controller({
#       Template: "user/greeting"
#       initialize: (user) ->
#         @logoutFormController = new LogoutFormController( user )
#         this.parent( user )
#     })
#     controller = new UserRowController( user )
#     controller.renderTo( $( "user-greeting" ) )
#
Rickshaw._Controller = new Class({

  $family: -> "Controller"

  Extends: Rickshaw._BaseController

  # Attached model instance. This is set when this controller is created.
  model: null

  # An array of model property strings that will be created as simple defer
  # methods on this controller that return the value of the property.
  DeferToModel: []

  initialize: (model, element, position) ->
    this.setModel( model, false ) if model
    this.parent( element, position )

  toString: -> "<Controller #{@$uuid}>"

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

window.Controller = Rickshaw.subclassConstructor( "Controller", Rickshaw._Controller )

# ListController
# --------------
#
# Render a List.
#
Rickshaw._ListController = new Class({

  $family: -> "ListController"

  Extends: Rickshaw._BaseController

  # Attached List instance. This is optionally set when this
  # controller is created.
  list: null

  # Either a Controller class or a function that takes a model
  # instance and returns the correct controller class for that model.
  Subcontroller: ->
    throw new Error "Subcontroller not set for #{this.toString()}."

  # Setup
  # -----

  initialize: (list, element, position) ->
    @_listView = null # TODO: unused?
    this.setList( list, false ) if list
    this.parent( element )

  toString: -> "<ListController #{@$uuid}>"

  # Returns new controller instance with the given model.
  subcontrollerFor: (model) ->
    @_subcontrollerType ||= Rickshaw.typeOf( this.Subcontroller )
    if @_subcontrollerType is "function"
      return new ( this.Subcontroller( model ) )( model )
    else if @_subcontrollerType is "class"
      return new this.Subcontroller( model )
    else
      throw new Error( "#{this}.Subclass must be a Class or a function that returns a Class." )

  # List
  # ----

  # Sets this controller's associated List instance and re-renders all
  # Metamorphs.
  setList: (list, render=true) ->
    unless Rickshaw.typeOf( list ) is "List"
      throw new Error "ListController#setList() must be passed a List instance. You passed a(n) #{Rickshaw.typeOf( list )}"
    if @list
      previousList = @list
      throw new Error "OK..."
    this._detachListEvents( @list ) if @list
    @list = list
    this._attachListEvents( @list )
    this.render() if render

  each: (fn) ->
    @list.each( fn )

  # Given a controller instance, hook up relay events on the list wrapper so
  # that events don't have to be attached to every single list item's elements.
  # If the controller class's events have already been hooked up, we don't have
  # to do anything here.
  _setupSubcontrollerEventRelays: (controller) ->
    controllerClass = controller.constructor
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
          controller = Rickshaw.Metamorph.findMetamorph( target, eventFn, selector, type ).controller
          eventFn.apply( controller, [e, target] ) # Fire the event.

    @_hasRelayedEvents[controllerClassUuid] = true

  # Events
  # ------

  # Hook up the List's events.
  _attachListEvents: (list) ->
    list.addEvents(
      add: this._onModelsAdd
      remove: this._onModelsRemove
      sort: this._onListSort
    )

  # Detach a List's events.
  _detachListEvents: (list) ->
    list.removeEvents(
      add: this._onModelsAdd
      remove: this._onModelsRemove
      sort: this._onListSort
    )

  # Hooks
  # -----

  _onModelsAdd: (list, models, position="unknown") ->
    return unless @rendered and models.length > 0
    switch position
      when "end"
        for model in models
          subcontroller = this.subcontrollerFor( model )
          this.fireEvent( "modelAppend", [subcontroller] )
      when "beginning"
        for model in models.reverse()
          subcontroller = this.subcontrollerFor( model )
          this.fireEvent( "modelPrepend", [subcontroller] )
      else
        this.render()

  # TODO
  _onModelsRemove: (list, models, position="unknown") ->
    return unless @rendered
    this.render()

  # TODO
  _onListSort: ->
    return unless @rendered
    this.render()

  Binds: ["_onModelsAdd", "_onModelsRemove", "_onListSort"]

})

window.ListController = Rickshaw.subclassConstructor( "ListController", Rickshaw._ListController )
