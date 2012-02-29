# List
# ====
#
# Array subclass for Model instances.
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

  $family: -> "List"

  Extends: Array
  Implements: [Events]

  # Options
  # -------

  # Default model class used when data (rather than model instances) are
  # given. If this is a function, it'll be passed the model data and it
  # should return the correct model class for the data.
  ModelClass: ->
    throw new Error "No ModelClass has been defined for this List"

  # Setup
  # -----

  initialize: ->
    this.push.apply( this, arguments ) if arguments.length > 0
    return this

  toString: -> "<List>"

  # Array of all model UUIDs. Used for detecting changes after sorts without
  # assuming that every sort actually changed the sort order.
  uuids: -> this.mapProperty( "$uuid" )

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
    this.push( model ) unless this.contains( model )
    return this

  combine: (models) ->
    models = this._prepareAddArgs( models )
    addedModels = []
    for model in models
      unless this.contains( model )
        Array::push.apply( this, [model] )
        addedModels.push model
    if addedModels.length > 0
      this.fireEvent( "add", [this, addedModels, "end"] )
    return this

  # Returns flat array of Model instances, pre-attached to this List.
  _prepareAddArgs: (args) ->
    models = this._ensureModels( Array.from( args ).flatten() )
    models.each( this._preattachModel )
    return models

  # Hook up the model's Events to this List's hooks only if it hasn't
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
    unless Rickshaw.isModelInstance( model )
      throw new Error "Can't erase non-model objects yet."
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
    removedModels = this.map( (obj) -> obj ) # new array
    this.length = 0
    this.fireEvent( "remove", [this, removedModels, "all"] )
    return this

  splice: (index, count, addModels...) ->
    removedModels = Array::splice.apply( this, [index, count] )
    removedModels.each( this._detachModel )
    this.fireEvent( "remove", [this, removedModels, index] ) if removedModels.length > 0

    if addModels.length > 0
      addModels = this._prepareAddArgs( addModels )
      Array::splice.apply( this, [index, 0].concat( addModels ) )
      this.fireEvent( "add", [this, addModels, index] )

    return removedModels

  _detachModel: (model) ->
    model.removeEvent "change", this._modelChanged
    model.removeEvent "delete", this._modelDeleted

  # Sorting
  # -------

  sort: (fnOrProp, direction="ascending") ->
    startOrder = this.uuids()
    if typeof fnOrProp is "function"
      this.parent fnOrProp
    else if typeof fnOrProp is "string"
      if direction is "descending"
        this.parent (a, b) -> Array._compare( b.get( fnOrProp ), a.get( fnOrProp ) )
      else
        this.parent (a, b) -> Array._compare( a.get( fnOrProp ), b.get( fnOrProp ) )
    else
      throw new Error "You must pass a model property as a string or a sort function."
    endOrder = this.uuids()
    this.fireEvent( "sort", [this] ) unless Array._equal( startOrder, endOrder )
    this

  _sortWithFn: (fn) ->
    Array::sort.pass this, [fn]

  reverse: ->
    return this if @length < 2
    Array::reverse.apply this
    this.fireEvent "sort", [this, "reverse"]

  # =========
  # = Hooks =
  # =========

  _modelChanged: (model, properties) ->
    this.fireEvent "change", [this, model, properties]

  _modelDeleted: (model) ->
    model.removeEvent()
    this.remove model

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
    if Rickshaw.isModelInstance( data )
      return data
    else
      if typeOf( @ModelClass ) is "function"
        klass = @ModelClass( data )
        return new klass( data )
      else
        return new @ModelClass( data )

  Binds: ["_modelChanged", "_modelDeleted", "_preattachModel", "_detachModel"]
})

window.List = Rickshaw.subclassConstructor( "List", Rickshaw._List )
