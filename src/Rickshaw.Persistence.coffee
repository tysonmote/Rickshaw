# Rickshaw.Persistence
# ====================

# Base persistence class. Don't use directly in your Model subclasses. All
# `Rickshaw.Persistence._Base` subclasses provide the following methods when
# mixed in with your `Model`:
#
#   * reload( callback )
#   * save( callback ) - Convenience method: calls create() or update() as needed.
#   * create( callback, failure_callback )
#   * update( callback )
#   * delete( callback )
window.Rickshaw.Persistence._Base = new Class({
  
  # Save / create / update
  
  save: (callback, failure_callback) ->
    if typeof @id in ["number", "string"]
      this.update( callback, failure_callback )
    else
      this.create( callback, failure_callback )
  
  create: (callback, failure_callback) ->
    @store.create( this, this._updated.bind( this, this.data, callback ), failure_callback )
  
  update: (callback, failure_callback) ->
    return unless this.isDirty()
    @store.update( this, this._updated.bind(this, this.data, callback ), failure_callback )
  
  _updated: (data, callback) ->
    changed = !Object._equal( data, @_previousData )
    this._setNewData( data )
    this._refreshId() unless typeof @id == "number"
    this.fireEvent( "dataChange", this ) if changed
    callback( this ) if callback
  
  # Reload
  
  reload: (callback) ->
    @store.read( this, (data) =>
      this._reloaded( data, callback )
    )
  
  _reloaded: (data, callback) ->
    changed = !Object._equal( data, @_previousData )
    this._setNewData( data )
    this.fireEvent( "dataChange", this ) if changed
    callback( this ) if callback
  
  # Delete
  
  delete: (callback, failure_callback) ->
    @store.delete( this, this._deleted.bind(this, [callback] ), failure_callback )
  
  _deleted: (callback) ->
    this._setNewData( {} )
    this.fireEvent( "afterDelete", this )
    callback( this ) if callback
  
  # Misc.
  
  _setNewData: (data) ->
    @data = data
    @_changedData = {}
    @_previousData = Object.clone( @data )
})

# REST-ful JSON persistence.
window.Rickshaw.Persistence.JSON = new Class({
  
  Extends: Rickshaw.Persistence._Base
  
  # TODO: These methods need to be bound to the model instance.
  store:
    paramName: "rickshaw"
    url: "/rickshaws"
    
    create: (model, callback, failure_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "create", model )
        data: this._createData( model )
        onSuccess: callback
        onFailure: failure_callback
      })).post()
    
    read: (model, callback, failure_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "read", model )
        onSuccess: callback
        onFailure: failure_callback
      })).get()
    
    update: (model, callback, failure_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "update", model )
        data: this._updateData( model )
        onSuccess: callback
        onFailure: failure_callback
      })).put()
    
    delete: (model, callback, failure_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "delete", model )
        onSuccess: callback
        onFailure: failure_callback
      })).delete()
    
    _buildUrl: (method, model) ->
      url = @url.substitute( model.data )
      switch method
        when "create" then url
        else "#{url}/#{model.id}"
    
    _createData: (model) ->
      this._namespaceData( model.data )
    
    _updateData: (model) ->
      this._namespaceData( Object.merge( model._changedData, {id: this.id} ) )
    
    _namespaceData: (data) ->
      return data unless typeof @paramName == "string"
      newData = {}
      newData[@paramName] = data
      newData
      
})

# HTML5 localStorage persistance
window.Rickshaw.Persistence.LocalStorage = new Class({
  
  Extends: Rickshaw.Persistence._Base
  
  # TODO: These methods need to be bound to the model instance.
  store:
    prefix: "rickshaw"
    
    create: (model, callback, failure_callback) ->
      this.update( model, callback, failure_callback )
    
    read: (model, callback, failure_callback) ->
      try
        callback( JSON.decode( localStorage[this._key( model )] ) )
      catch error
        failure_callback() if failure_callback
    
    update: (model, callback, failure_callback) ->
      try
        localStorage[this._key( model )] = JSON.encode( model.data )
        callback()
      catch error
        failure_callback() if failure_callback
    
    delete: (model, callback, failure_callback) ->
      try
        localStorage.removeItem( this._key( model ) )
        callback()
      catch error
        failure_callback() if failure_callback
    
    _key: (model) -> "#{@prefix}:#{model.id}"
})
