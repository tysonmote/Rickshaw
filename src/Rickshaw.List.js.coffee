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
    this._add( "push", arguments ) if arguments.length > 0
    return this

  # Array of all model UUIDs. Used for detecting changes after sorts without
  # assuming that every sort actuall changed the sort order.
  uuids: -> @models.mapProperty( "uuid" )

  # Adding
  # ------

  # Note: I tried refactoring these, but it just tended towards a weird mess
  # of if statements because of the different expected arguments and return
  # values for each Array method.

  push: (model) ->
    models = this._prepareAddArgs( model )
    result = Array.prototype.push.apply( this, models )
    this.fireEvent( "add", [this, models, "end"] )
    return result

  unshift: (model) ->
    models = this._prepareAddArgs( model )
    result = Array.prototype.unshift.apply( this, models )
    this.fireEvent( "add", [this, models, "beginning"] )
    return result

  include: (model) ->
    startingLength = @length
    models = this._prepareAddArgs( model )
    Array.prototype.push.apply( this, models )
    this.fireEvent( "add", [this, models, "beginning"] ) if startingLength != @length
    return this

  combine: (models) ->
    startingLength = @length
    models = this._prepareAddArgs( models )
    Array.prototype.combine.apply( this, models )
    if startingLength != @length
      newModels = this.slice( startingLength )
      this.fireEvent( "add", [this, newModels, "beginning"] )
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
    model = Array.prototype.pop.apply( this )
    this._detachModel( model  )
    this.fireEvent( "remove", [this, [model], "end"] )
    return model

  unshift: ->
    model = Array.prototype.unshift.apply( this )
    this._detachModel( model  )
    this.fireEvent( "remove", [this, [model], "beginning"] )
    return model

  erase: (model) ->
    throw "Can't erase non-model objects yet." unless model._uuid
    startingLength = @length
    Array.prototype.erase.apply( this, model )
    if startingLength != @length
      this._detachModel( model )
      this.fireEvent( "remove", [this, [model]] )
    return this

  empty: ->
    return if @length == 0
    this.each( this._detachModel )
    this.fireEvent( "remove", [this, this] )
    this.length = 0
    return this

  splice: (index, count, addModels...) ->
    removedModels = Array.prototype.splice.apply( this, arguments )
    removedModels.each( this._detachModel )
    this.fireEvent( "remove", [this, removedModels, index] ) if removedModels.length > 0

    if addModels.length > 0
      addModels = this._prepareAddArgs( addModels )
      Array.prototype.splice.apply( this, [index, 0, addModels] )
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
    Array.prototype.reverse.apply( this )
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
      if typeOf( item ) == "array"
        this._ensureModels( item )
      else
        this._modelFrom( item )
    )

  # Model can be a Model, a data hash, or an id (string / number). Returns
  # an instance of the model.
  _modelFrom: (data) ->
    if typeOf( data ) == "class"
      return data
    else
      if typeOf( @modelClass ) == "function"
        klass = @modelClass( data )
        return new klass( data )
      else
        return new @modelClass( data )

  Binds: ["_modelChanged", "_modelDeleted", "_preattachModel", "_detachModel"]
})

Rickshaw.List = Rickshaw.Utils.subclassConstructor( Rickshaw._List )
