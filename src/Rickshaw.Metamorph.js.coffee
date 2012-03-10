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

  $family: -> "Metamorph"

  # Create a new Metamorph but don't insert it into the DOM yet.
  initialize: (@view, html="") ->
    @_morph = Metamorph( html )
    return this

  toString: -> "<Rickshaw.Metamorph>"

  # Injecting
  # ---------

  inject: (element, position="bottom") ->
    element = $( element )
    switch position
      when "top"
        if firstChild = element.getFirst( "*" )
          this._injectBefore( firstChild )
        else
          @_morph.appendTo( element )
      when "before"
        this._injectBefore( element )
      when "after"
        this._injectAfter( element )
      else
        @_morph.appendTo( element )

    this._storeViewOnStartTag()
    return this

  _injectAfter: (element) ->
    this._rangedInject( element, "setStartAfter", "setEndAfter" )

  _injectBefore: (element) ->
    this._rangedInject( element, "setStartBefore", "setEndBefore" )

  _rangedInject: (element, startMethod, endMethod) ->
    range = document.createRange()
    range[startMethod]( element )
    range[endMethod]( element )
    fragment = range.createContextualFragment( @_morph.outerHTML() )
    range.insertNode( fragment )

  # Removing
  # --------

  remove: ->
    @_stored = false
    delete @_startMarkerElement
    delete @_endMarkerElement
    @_morph.remove()

  # Inner HTML
  # ----------

  # Set this Metamorph's inner HTML content.
  setHTML: (html) ->
    @_morph.html( html )
    this._storeViewOnStartTag()

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
      throw new Error "This Metamorph hasn't been inserted into the DOM yet."

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

  getElement: (selector) ->
    rootElements = this.rootElements()
    # root elements that match the selector
    match = rootElements.first (el) -> el.match( selector )
    # check descendant elements if needed
    unless match
      for el in rootElements
        match = el.getElement( selector )
        continue if match
    return match

  getElements: (selector) ->
    rootElements = this.rootElements()
    matches = new Elements()
    # root elements that match the selector
    matches.append( rootElements.filter( (el) -> el.match( selector ) ) )
    # descendant elements that match the selector
    matches.append( rootElements.getElements( selector ).flatten() )
    return matches

  # Ensure that the view is stored on the start marker tag
  _storeViewOnStartTag: ->
    unless @_stored
      this.startMarkerElement().store( "rickshaw-view", @view )
      @_stored = true
})

# Rickshaw.Metamorph.findView
# ===========================

# Given an element, and the event, selector, and type that was fired, return
# the corresponding view instance.
Rickshaw.Metamorph.findView = (element, eventFn, elementSelector, eventType) ->
  cursor = element
  until !cursor or Rickshaw.Metamorph.isMatchingMetamorph( cursor, eventFn, elementSelector, eventType )
    cursor = Rickshaw.Metamorph.findPreviousMetamorphStart( cursor )

  if cursor is null
    throw new Error "Rickshaw.Metamorph.findMetamorph() reached <body> without finding a matching Metamorph."
  else
    return cursor.retrieve( "rickshaw-view" )

# Return true if the given Metamorph start marker element should handle the
# given event.
Rickshaw.Metamorph.isMatchingMetamorph = (element, eventFn, elementSelector, eventType) ->
  unless element.tagName is "SCRIPT" and element.id?.match( /^metamorph-\d+-start$/ )
    return false
  controller = element.retrieve( "rickshaw-view" ).controller
  unless controllerFn = controller._boundEvents[elementSelector]?[eventType]
    return false
  # Resolve to instance method
  controllerFn = controller[controllerFn] if typeof controllerFn is "string"
  return controllerFn == eventFn

# Given an element, find the first Metamorph start tag above it. If no start tag
# can be found, null is returned.
Rickshaw.Metamorph.findPreviousMetamorphStart = (element) ->
  if previous = element.getPrevious( "script[type='text/x-placeholder']" )
    return previous
  else if parent = element.getParent()
    # Walk up the chain until we can find a previous-sibiling Metamorph tag
    return null if parent is document.body
    until parent is document.body or previous = parent.getPrevious( "script[type='text/x-placeholder']" )
      parent = parent.getParent()
    if parent is document.body
      return null
    else
      return previous
  else
    # We hit document.body
    return null
