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
    changed = !Object.equal( data, @_previousData )
    this._setNewData( data )
    this.fireEvent( "dataChange", this ) if changed
    this.fireEvent( "afterFetch", this )
    callback( this ) if callback
  
  save: (callback) ->
    if typeof @id in ["number", "string"]
      this.update()
    else
      this.create()
  
  create: (callback) ->
    @store.create( this, this._updated.bind( this ) )
  
  update: (callback) ->
    return unless this.isDirty()
    this.fireEvent( "beforePersist", this )
    @store.update( this, (data) =>
      this._updated( data, callback )
    )
  
  _updated: (data, callback) ->
    changed = !Object.equal( data, @_previousData )
    this._setNewData( data )
    this._refreshId() unless typeof @id == "number"
    this.fireEvent( "dataChange", this ) if changed
    this.fireEvent( "afterPersist", this )
    callback( this ) if callback
  
  delete: (callback) ->
    this.fireEvent( "beforeDelete", this )
    @store.delete( this, =>
      this._deleted( callback ) if callback
    )
  
  _deleted: (callback) ->
    this._setNewData( {} )
    this.fireEvent( "afterDelete", this )
    callback( this ) if callback
  
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
    
    create: (model, callback) ->
      (new Request.JSON({
        url: this._buildUrl( "create", model )
        data: this._createData( model )
        onSuccess: callback
        onFailure: -> #TODO
      })).post()
    
    read: (model, callback) ->
      (new Request.JSON({
        url: this._buildUrl( "read", model )
        onSuccess: callback
        onFailure: -> #TODO
      })).get()
    
    update: (model, callback) ->
      (new Request.JSON({
        url: this._buildUrl( "update", model )
        data: this._updateData( model )
        onSuccess: callback
        onFailure: -> #TODO
      })).put()
    
    delete: (model, callback) ->
      (new Request.JSON({
        url: this._buildUrl( "delete", model )
        onSuccess: callback
        onFailure: -> #TODO
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
