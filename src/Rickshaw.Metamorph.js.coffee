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
  initialize: (@controller, html="") ->
    Rickshaw.register( this )
    @_morph = Metamorph( html )
    return this

  toString: -> "<Rickshaw.Metamorph #{@$uuid}>"

  # Injecting
  # ---------

  # Insert this metamorph to a place relative to the given element's children.
  # Position can be "bottom" (default), "top", "after" or "before".
  inject: (element, position="bottom") ->
    element = $( element )
    switch location
      when "top"
        if firstChild = element.getElement( "*" )
          @_morph.above( firstChild )
        else
          @_morph.appendTo( element )
      when "before"
        @_morph.above( element )
      when "after"
        @_morph.below( element )
      else # "bottom"
        @_morph.appendTo( element )
    this.startMarkerElement().store( "rickshaw-controller", @controller )
    return this

  # Inner HTML
  # ----------

  # Set this Metamorph's inner HTML content.
  setHTML: (html) ->
    @_morph.html( html )
    this.startMarkerElement().store( "rickshaw-controller", @controller )

  # Metamorph markers
  # -----------------

  outerHTML: -> @_morph.outerHTML()

  startMarkerTag: -> @_morph.startTag()

  startMarkerElement: -> @_startMarkerElement ||= $( @_morph.start )

  endMarkerTag: -> @_morph.endTag()

  endMarkerElement: ->  @_endMarkerElement ||= $( @_morph.end )

  # Elements
  # --------

  # All root elements between the Metamorph's two marker tags as an Elements
  # array.
  rootElements: ->
    unless start = this.startMarkerElement()
      raise name: "MetamorphNotRendered", message: "This Metamorph hasn't been inserted into the DOM yet."

    rootElements = new Elements()
    selfIndex = parseInt @_morph.start.match( /\d+/ )
    nextElements = start.getAllNext( "*:not(#metamorph-#{selfIndex}-end)" )

    for el, i in nextElements
      if el.tagName is "SCRIPT" and el.id and idMatch = el.id.match( /^metamorph-(\d+)-start/ )
        # Found nested metamorph -- fast-forward to end tag
        seekEndId = "metamorph-#{idMatch[1]}-end"
        i = i + 1
        while el = nextElements[i] and not ( el.tagName is "SCRIPT" and el.id is seekEndId )
          i = i + 1
      else
        rootElements.push( el )

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
