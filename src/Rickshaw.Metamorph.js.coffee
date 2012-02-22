# Metamorph extensions


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
    if position is "top"
      if firstChild = element.getElement( "*" )
        this._injectBefore( firstChild )
      else
        @_morph.appendTo( element )
    else if position is "before"
      this._injectBefore( element )
    else if position is "after"
      this._injectAfter( element )
    else if position is "bottom"
      @_morph.appendTo( element )
    else
      throw new Error "\"#{position}\" is not a valid metamorph inject position."

    unless @storedOnStartMarker
      this.startMarkerElement().store( "rickshaw-metamorph", this )
      @storedOnStartMarker = true
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

  # Inner HTML
  # ----------

  # Set this Metamorph's inner HTML content.
  setHTML: (html) ->
    @_morph.html( html )
    unless @storedOnStartMarker
      this.startMarkerElement().store( "rickshaw-metamorph", this )
      @storedOnStartMarker = true

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

# Given an element, and the event, selector, and type that was fired, return
# the corresponding Rickshaw.Metamorph instance.
Rickshaw.Metamorph.findMetamorph = (element, eventFn, eventSelector, eventType) ->
  isMatchingMetamorph = (element) ->
    unless element.tagName is "SCRIPT" and element.id?.match( /^metamorph-\d+-start$/ )
      return false
    controller = element.retrieve( "rickshaw-metamorph" ).controller
    return false unless controller
    controllerFn = controller.Events[eventSelector]?[eventType]
    # Resolve to instance method
    controllerFn = controller[controllerFn] if typeof controllerFn is "string"
    return controllerFn == eventFn

  # Find previous sibling metamorph start tag, walking up the tree if
  # necessary.
  findPreviousMetamorphStart = (element) ->
    if previous = element.getPrevious( "script[type='text/x-placeholder']" )
      return previous
    else if parent = element.getParent()
      return parent if parent is document.body
      until parent is document.body or previous = parent.getPrevious( "script[type='text/x-placeholder']" )
        parent = parent.getParent()
      if parent is document.body
        return document.body
      else
        return previous
    else
      return document.body

  cursor = element
  until cursor is document.body or isMatchingMetamorph( cursor )
    cursor = findPreviousMetamorphStart( cursor )

  if cursor is document.body
    throw new Error "findController() reached <body> without finding a matching metamorph."
  else
    return cursor.retrieve( "rickshaw-metamorph" )
