# Rickshaw
# ========
# 
# Controllers have or have many Model instances. Views render HTML for a
# Controller.
#
window.Rickshaw = {

  version: "0.0.1"

  Templates: {}
  Persistence: {}

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
  refreshTemplates: (idRegex) ->
    idRegex ||= @templateRegex
    Rickshaw.Templates ||= {}
    $$( "script[id^='#{@templatePrefix}']" ).each( (el) ->
      if parsedId = idRegex.exec( el.get( "id" ) )
        name = parsedId.getLast()
        Rickshaw.Templates[name] = Handlebars.compile( el.get( "html" ) )
    )
    Rickshaw.Templates

  # Returns random "short uuid" of the form: "rickshaw-xxxx-xxxx-xxxx-xxxx"
  # Array.join() is faster than string concatenation here.
  uuid: ->
    str = ["rickshaw-"]
    i = 0
    while i++ < 17
      str.push if i != 9 then Math.round(Math.random() * 15).toString(16) else "-"
    str.join( "" )

  register: (object) ->
    object._uuid = Rickshaw.uuid()
    Rickshaw._objects[object._uuid] = object

  get: (uuid) ->
    @_objects[uuid]

  # Destroy the object and remove the _objects reference to it.
  # TODO: Do we need this?
  DELETE: (object) ->
    delete Rickshaw._objects[object._uuid]
}

document.addEvent( "domready", Rickshaw.refreshTemplates )

# Rickshaw.Utils
# ==============

Rickshaw.Utils = {
  equal: (a, b) ->
    aType = typeOf( a )
    if aType == "array"
      Array._equal( a, b )
    else if aType == "object"
      Object._equal( a, b )
    else
      a == b

  subclassConstructor: (baseClass) ->
    return( (params) ->
      new Class( Object.merge( { Extends: baseClass }, params ) )
    )
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
      switch typeof value
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
    return false unless "object" == typeOf( objectA )== typeOf( objectB )
    return false unless Object.keys( objectA ).sort().join( "" ) == Object.keys( objectB ).sort().join( "" )
    return Object.every( objectA, (value, key) ->
      switch typeof value
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
