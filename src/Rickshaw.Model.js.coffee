# Rickshaw.Model
# ==============
#
# The base building block of a Rickshaw app. Has data, fires events when said
# data changes.
#
# Events
# ------
#
#   * onDataChange( model, [propertyNames] ) - Fired once whenever any number
#     of properties change. An array of the names of changed properties is
#     passed.
#
#   * on[PropertyName]Change( model ) - Fired when a specific property is
#     changed.
#
# Custom Getters / Setters
# ------------------------
#
#     User = new Rickshaw.Model({
#       setName: (name) ->
#         [first, last] = name.split( " " )
#         this.set( "firstName", first )
#         this.set( "lastName", last )
#
#       getName: -> "#{this.get("firstName")} #{this.get("lastName")}"
#     })
#
# Custom setters should return `true` if the property was actually changed and
# `false` otherwise.
#
#     User = new Rickshaw.Model({
#       setFirstName: (firstName) ->
#         firstName = firstName.capitalize()
#         return false if @data.firstName == firstName
#         @data.firstName = firstName
#         return true
#     })
#
# Examples
# --------
#
#     User = new Rickshaw.Model({
#       getName: ->
#         [this.get( "firstName" ), this.get( "lastName" )].join( " " )
#       onLastNameChange: -> console.log( "*marraige bells*" )
#     })
#     u = new User( firstName: "Bubba", lastName: "Jones" )
#     u.get( "name" ) # "Bubba Jones"
#     u.set( "lastName", "Lolcat" ) # "*marraige bells*"
#
Rickshaw._Model = new Class({

  Implements: [Events]

  # Class Settings
  # --------------

  # Default property values. Any defaults that are functions will be executed
  # and passed this model instance at initialize time.
  #
  # Keep in mind that for new records, these default values wont be marked
  # dirty unless they are changed.
  defaults: {}

  # Setup
  # -----

  # Initialize a new model.
  initialize: (@data = {}) ->
    # Setup uuid
    Rickshaw.register( this )
    # Load defaults
    defaults = Object.map( @defaults, (value, key) ->
      if typeof( value ) == "function"
        value.apply( this, [this] )
      else
        value
    )
    # Setup data / properties
    @data = Object.merge( defaults, @data )
    @_previousData = Object.clone( @data )
    @_changedData = {}
    return this

  # State
  # -----

  # Returns true if this model contains data that hasn't been persisted yet.
  # TODO: Move to persistence layer.
  isDirty: -> Object.getLength( @_changedData ) > 0

  # Getters
  # -------

  # Return the value of the given property, using a custom getter (if defined).
  get: (property) ->
    # TODO: memoize custom getter names so we're not rebuilding the string all
    # the time. Maybe do the binding at initialize time, too.
    if customGetter = this["get#{property.forceCamelCase().capitalize()}"]
     customGetter.bind( this )()
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

    changedProperties = []

    # Update each value.
    Object.each( newData, (newValue, property) =>
      oldValue = @data[property]
      # TODO: same thing as getters above: memoize and bind and initialize time.
      if customSetter = this["set#{property.forceCamelCase().capitalize()}"]
        propertyChanged = customSetter.bind( this )( newValue )
      else
        propertyChanged = this._set( property, newValue )

      if propertyChanged
        changedProperties.push( property )
        @_changedData[property] = newValue
    )

    # Events
    changedProperties.each( (property) =>
      this.fireEvent( "#{property.forceCamelCase()}Change", this )
    )
    this.fireEvent( "change", [this, changedProperties] ) if changed

    return this

  # Update the value for the given property only if it is different. Returns
  # true if the property was changed and false otherwise.
  _set: (property, value) ->
    return false if Rickshaw.Utils.equal( @data[property], value )
    @data[property] = value
    @_changedData[property] = value
    return true

  Binds: ["_get", "_set"]

})

Rickshaw.Model = Rickshaw.Utils.subclassConstructor( Rickshaw._Model )
