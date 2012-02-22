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

  # Contains every single Rickshaw object, keyed by uuid. This means we keep
  # at least one reference to every single object, regardless if anything else
  # points to it. HelloooOOOoo memory leaks! TODO: Fix.
  _objects: {}

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
      if parsedId = idRegex.exec( el.get( "id" ) )
        name = parsedId.getLast()
        Rickshaw.Templates[name] = Handlebars.compile( el.get( "html" ) )
    )
    Rickshaw.Templates

  _uuidCounter: 0

  # Returns short unique id of the form: "rickshaw-\n+"
  uuid: ->
    "rickshaw-#{Rickshaw._uuidCounter++}"

  register: (object) ->
    object.$uuid = Rickshaw.uuid()
    Rickshaw._objects[object.$uuid] = object

  addParentClass: (object) ->
    unless uuid = object.$constructor.$uuid
      throw new Error "The given object (#{object.toString()}) doesn't have a parent Class with a UUID."
    object._class = Rickshaw.get( uuid )

  get: (uuid) ->
    @_objects[uuid]
}

document.addEvent( "domready", Rickshaw.refreshTemplates )

# Rickshaw.Utils
# ==============

Rickshaw.Utils = {
  # Deep clone the given object / array. Doesn't clone Element instances.
  clone: (item) ->
    switch typeOf( item )
      when "array" then return item.clone()
      when "object" then return Object.clone( item )
      else return item

  # Return true if the two given objects have equivalent values. Handles Arrays
  # and Objects.
  equal: (a, b) ->
    aType = typeOf( a )
    return false unless aType is typeOf( b )
    if aType is "array"
      Array._equal( a, b )
    else if aType is "object"
      Object._equal( a, b )
    else
      a == b

  # Return a Class constructor function that uses the given Class as a base
  # class. We use this so that we can use nested inheritance.
  subclassConstructor: (baseClass) ->
    (params) ->
      constructor = new Class( Object.merge( { Extends: baseClass }, params ) )
      Rickshaw.register constructor
      return constructor

  # Returns true if the given item is an instance of a Model subclass.
  isModelInstance: (item) ->
    !!( item.$uuid && item._get && item._set && item.data )

}

# MooTools Extensions
# ===================

Array.extend({
  # Returns true if the two arrays have the same values in the same order.
  # Handles nested arrays and objects.
  _equal: (arrayA, arrayB) ->
    return false unless "array" == typeOf( arrayA ) == typeOf( arrayB )
    return false unless arrayA.length == arrayB.length
    return arrayA.every( (value, index) ->
      switch typeOf( value )
        when "object" then Object._equal( value, arrayB[index] )
        when "array" then Array._equal( value, arrayB[index] )
        else value == arrayB[index]
    )

  _compare: (a, b) =>
    return -1 if a < b
    return 0 if a == b
    return 1
})

Array.implement({
  mapProperty: (property) ->
    this.map( (item) -> item[property] )
})

Object.extend({
  # Returns true if the two objects have the same keys and values. Handles
  # nested arrays and objects.
  _equal: (objectA, objectB) ->
    return false unless "object" == typeOf( objectA ) == typeOf( objectB )
    return false unless Object.keys( objectA ).sort().join( "" ) == Object.keys( objectB ).sort().join( "" )
    return Object.every( objectA, (value, key) ->
      switch typeOf( value )
        when "object" then Object._equal( value, objectB[key] )
        when "array" then Array._equal( value, objectB[key] )
        else value == objectB[key]
    )
})

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
