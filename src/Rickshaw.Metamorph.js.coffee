# Rickshaw.Metamorph
# ==================
#
# A more MooTools-like wrapper for Metamorph with some additional helper
# methods.
#
# Ideally, this would be an Element or Elements subclass, but it doesn't fit
# either of them, conceptually. A Metamorph is really a "range" of DOM elements
# that are treated as if they were contained by a wrapper element (but without
# the actual wrapper element).
#
Rickshaw.Metamorph = new Class({

  # Create a new Metamorph but doesn't insert it into the DOM yet.
  initialize: (html="") ->
    Rickshaw.register this
    @_morph = Metamorph html
    return this

  # Append this Metamorph inside the given element.
  inject: (element) ->
    @_morph.appendTo( $( element ) )

  # TODO: after and prepend for "below" and "above"

  # Set this Metamorph's inner HTML content.
  set: (prop, value) ->
    unless prop in ["html"]
      raise name: "ArgumentError", message: "Don't know how to set \"#{prop}\" on Rickshaw.Metamorphs"
    @_morph.html value

  outerHTML: -> @_morph.outerHTML()

  # Opening marker element.
  startMarkerElement: ->
    @_startMarkerElement ||= $( @_morph.start )

  # Ending marker element.
  endMarkerElement: ->
    @_endMarkerElement ||= $( @_morph.end )

  # All root elements between the Metamorph's two marker tags as an Elements
  # array.
  rootElements: ->
    unless start = this.startMarkerElement()
      raise name: "MetamorphNotRendered", message: "This Metamorph hasn't been inserted into the DOM yet."

    rootElements = new Elements()
    selfIndex = parseInt @_morph.start.match( /\d+/ )
    nextElements = start.getAllNext "*:not(script#metamorph-#{selfIndex}-end)"

    while el = nextElements.shift()
      # Nested metamorph start tag, skip to the matching end tag
      if el.tagName is "SCRIPT" and el.id and idMatch = el.id.match /^metamorph-(\d+)-start/
        seekEndId = "metamorph-#{idMatch[1]}-end"
        el = nextElements.shift()
        while not ( el.tagName is "SCRIPT" and el.id is seekEndId )
          el = nextElements.shift()
      else
        rootElements.push el

    return rootElements

  # Returns all elements that match the given selector, including root elements
  # of the Metamorph.
  getElements: (selector) ->
    rootElements = this.rootElements()
    matches = new Elements()
    # root elements that match the selector
    matches.append( rootElements.filter( (el) -> el.match( selector ) ) )
    # descendant elements that match the selector
    matches.append( rootElements.getElements( selector ).flatten() )
    return matches
})
