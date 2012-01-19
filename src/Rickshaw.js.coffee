# Rickshaw.Collection
# ===================
#
# Array-like collection of Model instances.
#
# Events
# ------
#
#   * onAdd( collection ) - Fired when elements are added.
#   * onRemove( collection ) - Fired when elements are removed.
#   * onSortChange( collection ) - Fired whenever the models are re-ordered.
#   * onChange( collection, instance, [properties] ) - Fired when any of the
#     model instances in this Collection change.
Rickshaw._Collection = new Class({

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

  uuids: -> @models.mappedProperty( "uuid" )

  # Adding
  # ------

  push:    -> this._add( "push", arguments )
  unshift: -> this._add( "unshift", arguments )
  include: -> this._add( "include", arguments )
  combine: -> this._add( "combine", arguments )
  append:  -> this._add( "append", arguments )

  # Run the given Array method with `args`, firing the "onAdd" event if
  # needed.
  _add: (method, args) ->
    startingLength = @length

    args = this._ensureModels( Array.from( args ) )
    args.flatten().each( (model) =>
      this._attachModel( model ) unless this.contains( model )
    )

    result = Array.prototype[method].apply( this, args )

    this.fireEvent( "add", [this] ) if startingLength != @length
    return result

  # Hook up the model's events to this Collection's hooks.
  _attachModel: (model) ->
    model.addEvent( "dataChange", this._modelDataChanged )
    model.addEvent( "afterDelete", this._modelDeleted )

  # Removing
  # --------

  # Note: splice is not currently supported.

  pop:     -> this._remove( "pop" )
  unshift: -> this._remove( "unshift" )
  erase:   -> this._remove( "erase", arguments )
  empty:   -> this._remove( "empty" )

  # Run the given Array method with `args` and fire the `onRemove` event if
  # needed.
  _remove: (method, args=[]) ->
    startingLength = @length

    if method == "erase"
      this._detachModel( args[0] )
    else if method == "empty"
      this.each( this._detachModel )

    result = Array.prototype[method].apply( this, args )

    if method in ["pop", "unshift"]
      this._detachModel( result ) if result && !this.contains( result )

    this.fireEvent( "remove", [this] ) if startingLength != @length
    return result

  _detachModel: (model) ->
    model.removeEvent( "dataChange", this._modelDataChanged )
    model.removeEvent( "afterDelete", this._modelDeleted )

  # Sorting
  # -------

  sort: (fn) ->
    startOrder = this.uuids()
    this.parent( fn )
    endOrder = this.uuids()
    this.fireEvent( "sortChange", [this] ) unless Array._equal( startOrder, endOrder )

  reverse: ->
    return this if @length < 2
    Array.prototype.reverse.apply( this )
    this.fireEvent( "sortChange", [this] )

  # =========
  # = Hooks =
  # =========

  # Bound to `this`.
  _modelDataChanged: (model, properties) ->
    this.fireEvent( "change", [this, model, properties] )

  # Bound to `this`.
  _modelDeleted: (model) ->
    model.removeEvent()
    this.remove( model )

  # =========
  # = Misc. =
  # =========

  _ensureModels: (array) ->
    array.map( (item) =>
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
        return new @modelClass( data )( data )
      else
        return new @modelClass( data )

  Binds: ["_modelDataChanged", "_modelDeleted", "_attachModel", "_detachModel"]
})

Rickshaw.Collection = Rickshaw.Utils.subclassConstructor( Rickshaw._Collection )
