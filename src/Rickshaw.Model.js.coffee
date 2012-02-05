# Model
# =====
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
#     User = new Model({
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
#     User = new Model({
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
#     User = new Model({
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

  # Options
  # -------

  # Default property values. Any defaults that are functions will be executed
  # and passed this model instance at initialize time.
  #
  # Keep in mind that for new records, these default values wont be marked
  # dirty unless they are changed.
  Defaults: {}

  # Setup
  # -----

  # Initialize a new model.
  initialize: (data = {}) ->
    # Setup uuid
    Rickshaw.register( this )
    this._initData data
    this._attachEvents()
    return this

  toString: -> "<Model #{@$uuid}>"

  _initData: (data) ->
    # Resolve defaults
    defaults = Object.map @__proto__.Defaults, (value, key) ->
      if typeof value is "function"
        value.apply this, [this]
      else
        value
    @data = Object.merge defaults, data
    @_previousData = Object.clone @data
    @dirtyProperties = []

  _attachEvents: ->
    Object.each @__proto__, (fn, name) =>
      if match = name.match( /^on([A-Z])([A-Za-z]+Change)$/ )
        event = match[1].toLowerCase() + match[2]
        this.addEvent event, -> fn.apply( this, arguments )
    if @__proto__.onChange
      this.addEvent "change", -> @__proto__.onChange.apply( this, arguments )

  # Getters
  # -------

  # Return the value of the given property, using a custom getter (if defined).
  # If many properties are passed, an object is returned.
  get: ->
    properties = Array.from( arguments ).flatten()
    if properties.length > 1
      return properties.map( (property) => this._get( property ) ).associate( properties )
    else
      return this._get properties[0]

  _get: (property) ->
    if customGetter = this["get#{property.forceCamelCase().capitalize()}"]
      customGetter.bind( this )()
    else
      @data[property]

  # Setters
  # -------

  # Update one property or many properties at once.
  #
  #     this.set( "name", "Bob" )
  #     this.set({ name: "Bob", age: 30 })
  #
  set: (property, value) ->
    if typeOf( property ) is "object"
      newData = property
    else
      newData = {}
      newData[property] = value

    changedProperties = []

    Object.each newData, (newValue, property) =>
      changedProperties.push property if this._set property, newValue

    # Events
    if changedProperties.length > 0
      changedProperties.each (property) =>
        this.fireEvent "#{property.forceCamelCase()}Change", this
      this.fireEvent "change", [this, changedProperties]

    return this

  # Toggle the value of the property (as a boolean). Undefined properties
  # will be `true` after being toggled a first time.
  toggle: (property) ->
    this.set property, !this.get( property )

  # Update the value for the given property only if it is different. Returns
  # true if the property was changed and false otherwise.
  _set: (property, value) ->
    newValue = Rickshaw.Utils.clone value
    if customSetter = this["set#{property.forceCamelCase().capitalize()}"]
      newValue = customSetter.apply this, [newValue]

    if Rickshaw.Utils.equal @_previousData[property], newValue
      @dirtyProperties = @dirtyProperties.erase property
    else
      @dirtyProperties.include property

    if Rickshaw.Utils.equal @data[property], newValue
      return false
    else
      @data[property] = newValue
      return true

  Binds: ["_get", "_set"]

})

window.Model = Rickshaw.Utils.subclassConstructor Rickshaw._Model
