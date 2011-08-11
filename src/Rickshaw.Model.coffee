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
  get: (property) ->
    if customGetter = @getters[property]
     customGetter.bind( this )( property )
    else
      this._get( property )
  
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
    
    # Update each value.
    Object.each( newData, (newValue, property) =>
      oldValue = @data[property]
      if customSetter = @setters[property]
        customSetter.bind( this )( newValue )
      else
        this._set( property, newValue )
      if oldValue != @data[property]
        changed = true
        @_changedData[property] = newValue
        this._firePropertyChangeHook( property )
    )
    this.fireEvent( "dataChange", this ) if changed
    return this
  
  # Update the value for the given property only if it is different.
  _set: (property, value) ->
    return if @data[property] == value
    @data[property] = value
    @_changedData[property] = value
  
  _firePropertyChangeHook: (property) ->
    method = "on#{property.camelCase().capitalize()}Change"
    if typeof this[method] == "function"
      this[method].bind( this )()
  
  # Misc.
  # -----
  
  _refreshId: -> @id = @data[@idProperty]
  
  Binds: ["_get", "_set"]
  
})
