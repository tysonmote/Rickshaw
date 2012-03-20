# Rickshaw
# ========
# 
# Controllers have or have many Model instances. Views render HTML for a
# Controller.
#
window.Rickshaw = {

  toString: -> "<Rickshaw global>"

  version: "0.0.1"

  Templates: {}

  # Auto-loaded templates
  # ---------------------

  templatePrefix: "Rickshaw"
  templateRegex: /^Rickshaw-(\w+)-template$/

  # Reload all templates from <script id="Rickshaw-*-template"> elements. This
  # is called on DOMReady, so you only need to call this if you're adding
  # templates after DOMReady.
  refreshTemplates: (idRegex=Rickshaw.templateRegex) ->
    Rickshaw.Templates ||= {}
    $$( "script[id^='#{Rickshaw.templatePrefix}']" ).each( (el) ->
      if parsedId = idRegex.exec( el.id )
        name = parsedId.getLast()
        Rickshaw.addTemplate( name, handlebars )
    )

  addTemplate: (name, handlebars) ->
    Rickshaw.Templates[name] = Handlebars.compile( handlebars, data: view: null )

  _uuidCounter: 0

  # Returns short unique id of the form: "rickshaw-\n+"
  uuid: ->
    "rickshaw-#{Rickshaw._uuidCounter++}"

  addUuid: (object) ->
    object.$uuid = Rickshaw.uuid()

  typeOf: (thing) ->
    switch type = typeOf( thing )
      when "object"
        thing.$rickshawType || "object"
      when "array"
        thing.$rickshawType || "array"
      else
        type

  # Utilities
  # ---------

  # Deep clone the given object / array. Doesn't clone Element instances.
  clone: (item) ->
    switch typeOf( item )
      when "array" then return Array.clone( item )
      when "object" then return Object.clone( item )
      else return item

  # Return true if the two given objects have equivalent values. Handles Arrays
  # and Objects.
  equal: (a, b) ->
    aType = typeOf( a )
    return false unless aType is typeOf( b )
    switch aType
      when "array" then return Array._equal( a, b )
      when"object" then return Object._equal( a, b )
      else return a == b

  # Return a Class constructor function that uses the given Class as a base
  # class. We use this so that we can use nested inheritance.
  subclassConstructor: (type, baseClass) ->
    return (params) ->
      params = Object.merge( { Extends: baseClass, $rickshawType: type }, params )
      constructor = new Class( params )
      return constructor

  # Returns true if the given item is an instance of a Model subclass.
  # TODO: Remove
  isModelInstance: (item) ->
    Rickshaw.typeOf( item ) == "Model"
}

document.addEvent( "domready", Rickshaw.refreshTemplates )

# MooTools Extensions
# ===================

# Array
# -----

# Returns true if the two arrays have the same values in the same order.
# Handles nested arrays and objects.
Array._equal = (arrayA, arrayB) ->
  return false unless "array" == typeOf( arrayA ) == typeOf( arrayB )
  return false unless arrayA.length == arrayB.length
  return true if arrayA is arrayB
  return arrayA.every( (value, index) -> Rickshaw.equal( value, arrayB[index] ) )

Array._compare = (a, b) ->
  return -1 if a < b
  return 0 if a == b
  return 1

Array.implement({
  first: (fn, bind) ->
    for element in this
      return element if fn.call( bind, element )
    return null

  mapProperty: (property) ->
    this.map( (item) -> item[property] )
})

# Object
# ------

# Returns true if the two objects have the same keys and values. Handles
# nested arrays and objects.
Object._equal = (objectA, objectB) ->
  return false unless "object" == typeOf( objectA ) == typeOf( objectB )
  return false unless Object.keys( objectA ).sort().join( "" ) == Object.keys( objectB ).sort().join( "" )
  return true if objectA is objectB
  return Object.every( objectA, (value, key) -> Rickshaw.equal( value, objectB[key] ) )

# String
# ------

String.implement({
  # Stronger camelCase. Converts "this is-the_remix" to "thisIsTheRemix"
  # instead of "this isThe_remix", like `camelCase()` would.
  forceCamelCase: ->
    String( this ).replace( /[-_\s]\D/g, (match) ->
      match.charAt( 1 ).toUpperCase()
    )
})

# Binds
# =====
#
# (From MooTools.More) Copy-pasta here so that we only depend on MooTools.Core.

Class.Mutators.Binds = (binds) ->
  this.implement( "initialize", -> ) if !@prototype.initialize
  Array.from( binds ).concat( @prototype.Binds || []);

Class.Mutators.initialize = (initialize) ->
  return( ->
    Array.from( @Binds ).each(
      ((name) ->
        if original = this[name]
          this[name] = original.bind(this)
      ),
      this
    )
    return initialize.apply( this, arguments )
  )
