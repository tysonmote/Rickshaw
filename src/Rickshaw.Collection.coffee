# Array-like collection of Model instances.
window.Rickshaw.Collection = new Class({
  
  Implements: [Events]
  
  # ===========
  # = Options =
  # ===========
  
  modelClass: Rickshaw.Model
  
  # =========
  # = Setup =
  # =========
  
  models: []
  
  initialize: (models = []) ->
    @length = 0
    this.include( models )
  
  # ================
  # = Add / remove =
  # ================
  
  include: (models) -> this._add( "include", models )
  
  append: (models) -> this._add( "push", models )
  
  _add: (method, models) ->
    startingLength = @length
    Array.from( models ).each( (model) =>
      model = this._modelFrom( model )
      @models[method]( model )
      this._attachModel( model )
    )
    @length = @models.length
    this.fireEvent( "add", this ) if startingLength != @length
  
  # Hook up the model's events to this Collection's hooks.
  _attachModel: (model) ->
    model.addEvent( "dataChange", this._modelDataChanged )
    model.addEvent( "afterDelete", this._modelDeleted )
  
  remove: (model) ->
    startingLength = @length
    @models.erase( model )
    @length = @models.length
    this.fireEvent( "remove", this ) if startingLength != @length
  
  _detachModel: (model) ->
    model.removeEvent( "dataChange", this._modelDataChanged )
    model.removeEvent( "afterDelete", this._modelDeleted )
  
  # =============
  # = Iterators =
  # =============
  
  each: (fn, bind) -> @models.each( fn, bind )
  every: (fn, bind) -> @models.every( fn, bind )
  # filter: (fn, bind) -> @models.filter( fn, bind ) # Should this return a new Collection?
  map: (fn, bind) -> @models.map( fn, bind )
  some: (fn, bind) -> @models.some( fn, bind )
  
  # =========
  # = Hooks =
  # =========
  
  # Bound to this
  _modelDataChanged: (model) ->
    this.fireEvent( "change", [this, model] )
  
  # Bound to this
  _modelDeleted: (model) ->
    model.removeEvent()
    this.remove( model )
  
  # =========
  # = Misc. =
  # =========
  
  # Model can be a Model, a data hash, or an id (string / number). Returns
  # an instance of the model.
  _modelFrom: (data) ->
    if typeOf( data ) == "class"
      if instanceOf( data, @modelClass )
        return data
      else
        # TODO: Allow Collection to hold different Model subclasses?
        throw "Model is not an instance of the expected class."
    else
      return new @modelClass( data )
  
  Binds: ["_modelDataChanged", "_modelDeleted"]
})
