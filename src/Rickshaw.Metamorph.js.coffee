# Rickshaw.Metamorph
# ==================
#
# A more MooTools-like wrapper for Metamorph with some additional helper
# methods.
#
# Ideally, this would be an Element or Elements subclass, but it doesn't fit
# either of them. A Metamorph is essentially a "range" of DOM elements that is
# treated as if it was a wrapper element (but without the actual element).
#
Rickshaw.Metamorph = new Class({

  initialize: (html="") ->
    Rickshaw.register( this )
    @_morph = Metamorph( html )
    return this

  # Append this Metamorph to the given element.
  inject: (element) ->
    @_morph.appendTo( $( element ) )

  # Return the placeholder tags that this metamorph will render to.
  placeholderHTML: ->
    @_morph.startTag() + @_morph.endTag()

  # Set this Metamorph's inner HTML content.
  set: (prop, value) ->
    unless prop in ["html"]
      raise "Don't know how to set \"#{prop}\" on Rickshaw.Metamorphs"
    @_morph.html( value )

  outerHTML: -> @_morph.outerHTML()

  # Opening marker tag.
  _startElement: ->
    @__startElement ||= $( @_morph.start )

  # All root elements between the Metamorph's two marker tags.
  rootElements: ->
    start = this._startElement()
    raise "This Metamorph hasn't been inserted into the DOM yet." unless start
    return start.getAllNext( "*:not(script[type='text/x-placeholder'])" )

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
