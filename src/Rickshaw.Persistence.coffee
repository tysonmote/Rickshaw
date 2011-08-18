# Rickshaw.Persistence
# ====================

# Base persistence class. Don't use directly in your Model subclasses. All
# `Rickshaw.Persistence._Base` subclasses provide the following methods when
# mixed in with your `Model`:
#
#   * reload( callback )
#   * save( callback ) - Convenience method: calls create() or update() as needed.
#   * create( callback )
#   * update( callback )
#   * delete( callback )
window.Rickshaw.Persistence._Base = new Class({
  
  reload: (callback) ->
    this.fireEvent( "beforeFetch", this )
    @store.read( this, (data) =>
      this._reloaded( data, callback )
    )
  
  _reloaded: (data, callback) ->
    changed = !Object._equal( data, @_previousData )
    this._setNewData( data )
    this.fireEvent( "dataChange", this ) if changed
    this.fireEvent( "afterFetch", this )
    callback( this ) if callback
  
  save: (callback, fail_callback) ->
    if typeof @id in ["number", "string"]
      this.update( callback, fail_callback )
    else
      this.create( callback, fail_callback )
  
  create: (callback, fail_callback) ->
    @store.create( this, this._updated.bind( this, [this.data, callback] ), fail_callback )
  
  update: (callback, fail_callback) ->
    return unless this.isDirty()
    this.fireEvent( "beforePersist", this )
    @store.update( this, this._updated.bind(this, [this.data, callback] ), fail_callback )
  
  _updated: (data, callback) ->
    changed = !Object._equal( data, @_previousData )
    this._setNewData( data )
    this._refreshId() unless typeof @id == "number"
    this.fireEvent( "dataChange", this ) if changed
    this.fireEvent( "afterPersist", this )
    callback( this ) if callback
  
  delete: (callback, fail_callback) ->
    this.fireEvent( "beforeDelete", this )
    @store.delete( this, this._deleted.bind(this, [callback] ), fail_callback )
  
  _deleted: (callback) ->
    this._setNewData( {} )
    this.fireEvent( "afterDelete", this )
    callback( this ) if callback
  
  _setNewData: (data) ->
    @data = data
    @_changedData = {}
    @_previousData = Object.clone( @data )

  _persistFail: (callback, xhr)->
    this.fireEvent( "persistFail", this )
    callback( this, xhr ) if callback
})

# REST-ful JSON persistence.
window.Rickshaw.Persistence.JSON = new Class({
  
  Extends: Rickshaw.Persistence._Base
  
  # TODO: These methods need to be bound to the model instance.
  store:
    paramName: "rickshaw"
    url: "/rickshaws"
    
    create: (model, callback, fail_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "create", model )
        data: this._createData( model )
        onSuccess: this._successCallbackWrapper( callback )
        onFailure: this._failCallbackWrapper( model, fail_callback )
      })).post()
    
    read: (model, callback, fail_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "read", model )
        onSuccess: this._successCallbackWrapper( callback )
        onFailure: -> this._failCallbackWrapper( model, fail_callback )
      })).get()
    
    update: (model, callback, fail_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "update", model )
        data: this._updateData( model )
        onSuccess: this._successCallbackWrapper( callback )
        onFailure: -> this._failCallbackWrapper( model, fail_callback )
      })).put()
    
    delete: (model, callback, fail_callback) ->
      (new Request.JSON({
        url: this._buildUrl( "delete", model )
        onSuccess: this._successCallbackWrapper( callback )
        onFailure: -> this._failCallbackWrapper( model, fail_callback )
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

    _successCallbackWrapper: (callback) ->
      ( json, text ) ->
        callback()

    _failCallbackWrapper: (model, callback) ->
      ( xhr ) ->
        model._persistFail(callback, xhr)
       
})
