# Rickshaw.Controllers
# ====================

window.Rickshaw.Controllers.Single = new Class({
  
  Implements: [Events]
  
  # Options
  # -------
  
  # Associated `Rickshaw.Model` subclass. (Required.)
  modelClass: Rickshaw.Model
  
  # Name of template used to render this controller. (Required if you want to,
  # you know, render anything.)
  templateName: "Single"
  
  # Element attribute which contains the id of the model. (Optional.)
  idAttribute: "data-id"
  
  # Auto-attached element events. Keyed by element selector. (Optional.)
  elementEvents: {}
  
  # If true, the rendered element is destroyed when the model is destroyed.
  unrenderOnDelete: true
  
  # Properties
  # ----------
  
  # Attached model instance. This is set on controller instantiation.
  model: null
  
  # Render state of this controller.
  rendered: false
  
  # Params:
  #
  #   * `element` - DOM element that this controller's HTML is rendered to.
  #   * `data` - Model instance or model data of associated model.
  initialize: (@element, data = {}) ->
    @element.store( "Rickshaw.Controller", this )
    
    @model = this._modelFrom( data )
    
    this._attachModel()
    return this
  
  # Hook up the model's events.
  _attachModel: ->
    @model.addEvent( "dataChange", this._modelDataChanged.bind( this ) )
    @model.addEvent( "afterDelete", this._modelDeleted.bind( this ) )
  
  render: ->
    throw "No Element to render to!" unless @element
    this.fireEvent( "beforeRender", this )
    @element.set( "html", this._toHtml() )
    this._attachEvents()
    @rendered = true
    this.fireEvent( "afterRender", this )
  
  _attachEvents: ->
    @_boundElementEvents ||= {}
    Object.each( @elementEvents, (events, selector) =>
      # TODO: Wtf is up with the __proto__ BS?
      @_boundElementEvents[selector] ||= Object.map( events.__proto__, (fn, eventName) =>
        return fn.bind( this )
      )
      @element.getElements( selector ).addEvents( @_boundElementEvents[selector] )
    )
  
  _toHtml: ->
    templateData = @model.data
    template = Rickshaw.Templates[@templateName]
    if template
      return template( templateData )
    else
      throw "Template \"#{@templateName}\" not found."
  
  # =========
  # = Hooks =
  # =========
  
  _modelDataChanged: ->
    this.render()
  
  _modelDeleted: ->
    if @unrenderOnDelete
      @element.set( "html", "" )
      @rendered = false
  
  # Misc.
  # -----
  
  _modelFrom: (data) ->
    if typeOf( data ) == "object" && instanceOf( data, @modelClass )
      return data
    else
      return new @modelClass( data )
  
})

window.Rickshaw.Controllers.Summary = new Class({
  
  Implements: [Events]
  
  templateName: ""
  elementEvents: {}
  
  element: null
  models: []
  
  initialize: (@element, @models ) ->
    @rendered = false
    @models.each( (model) => this._attachModel( model ) )
    return this
  
  # Should return an object that gets passed to Mustache with the template.
  summarize: (models) ->
    throw "`summarize()` is not implemented by this Rickshaw.Controllers.Summary subclass."
  
  render: ->
    return false unless @element
    this.fireEvent( "beforeRender", this )
    @element.set( "html", this._toHtml() )
    this._attachEvents()
    @rendered = true
    this.fireEvent( "afterRender", this )
  
  _toHtml: ->
    # Todo: Someday we parallelize this with WebWorkers. Har har.
    templateData = this.summarize( @models )
    template = Rickshaw.Templates[@templateName]
    if template
      return template( templateData )
    else
      throw "Template \"#{@templateName}\" not found."
  
  _attachModel: (model) ->
    model.addEvent( "dataChange", this._modelDataChanged )
    model.addEvent( "afterDelete", this._modelDeleted )
  
  _detachModel: (model) ->
    model.removeEvent( "dataChange", this._modelDataChanged )
    model.removeEvent( "afterDelete", this._modelDeleted )
  
  # This shit needs to be DRYed up, for reals.
  _attachEvents: ->
    @_boundElementEvents ||= {}
    Object.each( @elementEvents, (events, selector) =>
      # TODO: Wtf is up with the __proto__ BS?
      @_boundElementEvents[selector] ||= Object.map( events.__proto__, (fn, eventName) =>
        return fn.bind( this )
      )
      @element.getElements( selector ).addEvents( @_boundElementEvents[selector] )
    )
  
  # =========
  # = Hooks =
  # =========
  
  _modelDataChanged: (model) ->
    this.render() if @rendered
  
  _modelDeleted: (model) ->
    @models.erase( model )
    this.render() if @rendered
  
  Binds: ["_modelDataChanged", "_modelDeleted"]
  
})
