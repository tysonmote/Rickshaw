# Rickshaw.List
# =============
#
# Array-like list of Model instances.
#
# Events
# ------
#
#   * onAdd( list, [models], location ) - Fired when objects are added.
#     `location` is where the models were added: "end" or "beginning" (or a
#     specific index integer, when splice() is used).
#   * onRemove( list, [models], location ) - Fired when objects are removed.
#     `models` is an array of removed models. `location` is the location that
#     the models were removed from: "end" or "beginning" (or a
#     specific index integer, when splice() is used).
#   * onSort( list ) - Fired whenever the models are re-ordered.
#   * onChange( list, model, [properties] ) - Fired when any of the model
#     instances in this List change.
#
Rickshaw._List = new Class({

  Extends: Array
  Implements: [Events]

  # Options
  # -------

  # Default model class used when data (rather than model instances) are
  # given. If this is a function, it'll be passed the model data and it
  # should return the correct model class for the data.
  modelClass: Rickshaw.Model

  # Properties
  # ----------

  models: []

  # Setup
  # -----

  initialize: ->
    Rickshaw.register( this )
    this.push.apply( this, arguments ) if arguments.length > 0
    return this

  # Array of all model UUIDs. Used for detecting changes after sorts without
  # assuming that every sort actuall changed the sort order.
  uuids: -> @models.mapProperty( "uuid" )

  # Adding
  # ------

  # Note: I tried refactoring these, but it just tended towards a weird mess
  # of if statements because of the different expected arguments and return
  # values for each Array method.

  push: ->
    models = this._prepareAddArgs( arguments )
    result = Array::push.apply( this, models )
    this.fireEvent( "add", [this, models, "end"] )
    return result

  unshift: ->
    models = this._prepareAddArgs( arguments )
    result = Array::unshift.apply( this, models )
    this.fireEvent( "add", [this, models, "beginning"] )
    return result

  include: (model) ->
    startingLength = @length
    models = this._prepareAddArgs( model )
    Array::include.apply( this, models )
    this.fireEvent( "add", [this, models, "beginning"] ) if startingLength != @length
    return this

  combine: (models) ->
    startingLength = @length
    models = this._prepareAddArgs( models )
    Array::combine.apply( this, [models] )
    if startingLength != @length
      newModels = this.slice( startingLength )
      this.fireEvent( "add", [this, newModels, "end"] )
    return this

  # Returns flat array of Model instances, pre-attached to this List.
  _prepareAddArgs: (args) ->
    models = this._ensureModels( Array.from( args ).flatten() )
    models.each( this._preattachModel )
    return models

  # Hook up the model's events to this List's hooks only if it hasn't
  # been hooked up already (aka exists in this List).
  _preattachModel: (model) ->
    return false if this.contains( model )
    model.addEvents(
      change: this._modelChanged
      delete: this._modelDeleted
    )

  # Removing
  # --------

  pop: ->
    model = Array::pop.apply( this )
    this._detachModel( model  )
    this.fireEvent( "remove", [this, [model], "end"] )
    return model

  shift: ->
    model = Array::shift.apply( this )
    this._detachModel( model  )
    this.fireEvent( "remove", [this, [model], "beginning"] )
    return model

  # MooTools's implementation uses this.splice() and doesn't return the indexes
  # that were removed, so here's our own hot implementation here.
  erase: (model) ->
    unless Rickshaw.Utils.isModelInstance( model )
      throw name: "ModelRequired", message: "Can't erase non-model objects yet."
    i = @length
    removedIndexes = []
    while i--
      if this[i] is model
        removedIndexes.push( i )
        Array::splice.apply( this, [i, 1] )
    if removedIndexes.length > 0
      this._detachModel( model )
      this.fireEvent( "remove", [this, [model], removedIndexes] )
    return this

  empty: ->
    return if @length is 0
    this.each( this._detachModel )
    this.fireEvent( "remove", [this, this] )
    this.length = 0
    return this

  splice: (index, count, addModels...) ->
    removedModels = Array::splice.apply( this, arguments )
    removedModels.each( this._detachModel )
    this.fireEvent( "remove", [this, removedModels, index] ) if removedModels.length > 0

    if addModels.length > 0
      addModels = this._prepareAddArgs( addModels )
      Array::splice.apply( this, [index, 0, addModels] )
      this.fireEvent( "add", [this, addModels, index] )

    return removedModels

  _detachModel: (model) ->
    model.removeEvent( "change", this._modelChanged )
    model.removeEvent( "delete", this._modelDeleted )

  # Sorting
  # -------

  sort: (fn) ->
    startOrder = this.uuids()
    this.parent( fn )
    endOrder = this.uuids()
    this.fireEvent( "sort", [this] ) unless Array._equal( startOrder, endOrder )

  reverse: ->
    return this if @length < 2
    Array::reverse.apply( this )
    this.fireEvent( "sort", [this] )

  # =========
  # = Hooks =
  # =========

  _modelChanged: (model, properties) ->
    this.fireEvent( "change", [this, model, properties] )

  _modelDeleted: (model) ->
    model.removeEvent()
    this.remove( model )

  # =========
  # = Misc. =
  # =========

  # Turns any non-Model instance objects in the array to their appropriate
  # Model instances.
  _ensureModels: (array) ->
    Array.from( array ).map( (item) =>
      if typeOf( item ) is "array"
        this._ensureModels( item )
      else
        this._modelFrom( item )
    )

  # Returns a model instance for the given parameter. Model can be a Model
  # instance (in which case it is simply returned) or a data hash, from which
  # a new model instance will be returned.
  _modelFrom: (data) ->
    if Rickshaw.Utils.isModelInstance( data )
      return data
    else
      if typeOf( @modelClass ) is "function"
        klass = @modelClass( data )
        return new klass( data )
      else
        return new @modelClass( data )

  Binds: ["_modelChanged", "_modelDeleted", "_preattachModel", "_detachModel"]
})

Rickshaw.List = Rickshaw.Utils.subclassConstructor( Rickshaw._List )
