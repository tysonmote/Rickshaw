# Rickshaw.Model
# ==============

window.Rickshaw.Model = new Class({
  
  Implements: [Events]
  
  # Unique identifier property key for Model instances in its data.
  idProperty: "id"
  
  # Custom property getters keyed by property name.
  getters: {}
  
  # Custom property setters keyed by property name.
  setters: {}
  
  # Setup
  # -----
  
  # Initialize a new model. `data` can be either an ID number / string or a
  # properties object.
  initialize: (@data = {}) ->
    if typeof @data in ["number", "string"]
      newData = {}
      newData[@idProperty] = @data
      @data = newData
    
    @_previousData = Object.clone( @data )
    @_changedData = {}
    this._refreshId()
    
    return this
  
  # State
  # -----
  
  # Returns true if this model contains data that hasn't been persisted yet.
  isDirty: -> Object.getLength( @_changedData ) > 0
  
  # Getters
  # -------
  
  # Return the value of the given property, using a custom getter (if defined).
  get: (property) -> (@getters[property] || this._get)(property)
  
  _get: (property) -> @data[property]
  
  # Setters
  # -------
  
  # Update one property or many properties at once.
  #
  #     this.set( "name", "Bob" )
  #     this.set({ name: "Bob", age: 30 })
  #
  set: (property, value) ->
    if typeof property == "object"
      newData = property
    else
      newData = {}
      newData[property] = value
    
    changed = false
    Object.each( newData, (value, property) =>
      if (@setters[property] || this._set)(property, value)
        changed = true
    )
    this.fireEvent( "dataChange", this ) if changed
    return this
  
  # Return true if `property` was changed to `value`. If the property was
  # already set to `value`, false is returned.
  _set: (property, value) ->
    return false if @data[property] == value
    @data[property] = value
    @_changedData[property] = value
    true
  
  # Misc.
  # -----
  
  _refreshId: -> @id = @data[@idProperty]
  
  Binds: ["_get", "_set"]
  
})
