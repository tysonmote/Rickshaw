# Rickshaw.Controller
# ===========================
#
# Events
# ------
#
#   * onBeforeRender(controller) - Fired before the controller is rendered.
#   * onAfterRender(controller) - Fired after the controller is rendered.
#
# Examples
# --------
#
#     # Template:
#     <p>Hello, {{ fullName }}!</p>
#
#     # Controller
#     UserGreetingController = new Rickshaw.Controller({
#       templateName: "user/greeting"
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
#       initialize: (user) ->
#         @logoutFormController = new LogoutFormController( user )
#         this.parent( user )
#       templateName: "user/greeting"
#     })
#     controller = new UserRowController( user )
#     controller.renderTo( $( "user-greeting" ) )

Rickshaw._Controller = new Class({

  Implements: [Events]

  # Options
  # -------

  # Name of template used to render this controller. (Required)
  templateName: ""

  # Auto-attached element events. Keyed by element selector. (Optional)
  events: {}

  # Properties
  # ----------

  # Attached model instance. This is set when this controller is created.
  model: null

  # Container elements that this controller renders to.
  elements: null

  # If this is a sub-controller, this is the parent controller.
  parentController: null

  # Params:
  #
  #   * `model` (Rickshaw.Model) - Associated model.
  #   * `element` (Element, Elements, String, null) - DOM element, elements,
  #     or element id that this controller's rendered template HTML is rendered
  #     to. If this is null, it can be set to an Element or Elements later (as
  #     in the case of subController).
  initialize: (model=null, element=null) ->
    Rickshaw.register( this )
    @elements = $$()
    this.setModel( model, false ) if model
    this.renderTo( element ) if element
    return this

  # Sets this controller's associated model instance and renders to all
  # elements.
  setModel: (model, render=true) ->
    this._detachModelEvents() if @model
    @model = model
    this._attachModelEvents()
    this.render() if render

  # Rendering
  # ---------

  # Setup a render destination element.
  renderTo: (element) ->
    @elements.push( $( element ) )
    this.render()

  # TODO: Render only what needs to be re-rendered.
  render: ->
    return unless @elements.length > 0
    this.fireEvent( "beforeRender", this )
    @elements.set( "html", this._toHtml() )
    this._renderSubControllers()
    this._attachEvents()
    this.fireEvent( "afterRender", this )

  _renderSubControllers: ->
    self = this
    @elements.each( (container) ->
      container.getElements( ".rickshaw-subcontroller.rickshaw-unrendered" ).each( (el) ->
        controller = Rickshaw[el.get( "data-uuid" )]
        controller.parentController = self
        controller.renderTo( el )
        el.removeClass( "rickshaw-unrendered" )
      )
    )

  _toHtml: ->
    if template = Rickshaw.Templates[@templateName]
      return template( this )
    else
      throw "Template \"#{@templateName}\" not found."

  # Events
  # ------

  _attachEvents: ->
    @_boundEvents ||= {}
    Object.each( @events, (events, selector) =>
      # TODO: Wtf is up with the __proto__ BS?
      @_boundEvents[selector] ||= Object.map( events.__proto__, (fn, eventName) =>
        return fn.bind( this )
      )
      @elements.getElements( selector ).addEvents( @_boundEvents[selector] )
    )

  # Hook up the model's events.
  _attachModelEvents: ->
    @model.addEvent( "dataChange", this._modelDataChanged )
    @model.addEvent( "afterDelete", this._modelDeleted )

  _detachModelEvents: ->
    @model.removeEvent( "dataChange", this._modelDataChanged )
    @model.removeEvent( "afterDelete", this._modelDeleted )

  # Hooks
  # -----

  # bound
  # TODO: only re-render the parts that need re-rendering
  _modelDataChanged: (model, changedProperties) ->
    this.render()

  # bound
  # TODO: This should be non-sucky.
  _modelDeleted: ->
    @elements.destroy()

  Binds: ["_modelDataChanged", "_modelDeleted"]

})

Rickshaw.Controller = Rickshaw.Utils.subclassConstructor( Rickshaw._Controller )

# Rickshaw.ListController
# -----------------------

Rickshaw._ListController = new Class({

  Implements: [Events]

  # Options
  # -------

  # Name of template used to render this controller. (Required)
  templateName: ""

  # Auto-attached element events. Keyed by element selector. (Optional)
  events: {}

  # Properties
  # ----------

  # Attached collection instance. This is set when this controller is created.
  collection: null

  # Container elements that this controller renders to.
  elements: null

  # If this is a sub-controller, this is the parent controller.
  parentController: null

  # Params:
  #
  #   * `collection` (Rickshaw.Collection) - Associated Collection.
  #   * `element` (Element, Elements, String, null) - DOM element, elements,
  #     or element id that this controller's rendered template HTML is rendered
  #     to. If this is null, it can be set to an Element or Elements later (as
  #     in the case of subController).
  initialize: (collection=null, element=null) ->
    Rickshaw.register( this )
    @elements = $$()
    this.setCollection( collection, false ) if model
    this.renderTo( element ) if element
    return this

  # Sets this controller's associated model instance and renders to all
  # elements.
  setCollection: (collection, render=true) ->
    this._detachModelEvents() if @model
    @model = model
    this._attachModelEvents()
    this.render() if render

  # Rendering
  # ---------

  # Setup a render destination element.
  renderTo: (element) ->
    @elements.push( $( element ) )
    this.render()

  # TODO: Render only what needs to be re-rendered.
  render: ->
    return unless @elements.length > 0
    this.fireEvent( "beforeRender", this )
    @elements.set( "html", this._toHtml() )
    this._renderSubControllers()
    this._attachEvents()
    this.fireEvent( "afterRender", this )

  _renderSubControllers: ->
    self = this
    @elements.each( (container) ->
      container.getElements( ".rickshaw-subcontroller.rickshaw-unrendered" ).each( (el) ->
        controller = Rickshaw[el.get( "data-uuid" )]
        controller.parentController = self
        controller.renderTo( el )
        el.removeClass( "rickshaw-unrendered" )
      )
    )

  _toHtml: ->
    if template = Rickshaw.Templates[@templateName]
      return template( this )
    else
      throw "Template \"#{@templateName}\" not found."

  # Events
  # ------

  _attachEvents: ->
    @_boundEvents ||= {}
    Object.each( @events, (events, selector) =>
      # TODO: Wtf is up with the __proto__ BS?
      @_boundEvents[selector] ||= Object.map( events.__proto__, (fn, eventName) =>
        return fn.bind( this )
      )
      @elements.getElements( selector ).addEvents( @_boundEvents[selector] )
    )

  # Hook up the model's events.
  _attachModelEvents: ->
    @model.addEvent( "dataChange", this._modelDataChanged )
    @model.addEvent( "afterDelete", this._modelDeleted )

  _detachModelEvents: ->
    @model.removeEvent( "dataChange", this._modelDataChanged )
    @model.removeEvent( "afterDelete", this._modelDeleted )

  # Hooks
  # -----

  # bound
  # TODO: only re-render the parts that need re-rendering
  _modelDataChanged: ->
    this.render()

  # bound
  # TODO: This should be non-sucky.
  _modelDeleted: ->
    @elements.destroy()

  Binds: ["_modelDataChanged", "_modelDeleted"]

})
