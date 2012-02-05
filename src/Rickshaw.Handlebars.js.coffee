# Handlebars
# ==========
#
# Handlebars helpers for Rickshaw.

# subController
# -------------
#
# Render a Controller / ListController instance in-place.
#
Handlebars.registerHelper "subController", (controller, options) ->
  unless arguments.length is 2
    throw new Error "You must supply a controller instance to \"subController\"."
  unless controller
    throw new Error "Invalid controller passed to the subController template helper."
  morph = this._setupSubcontroller( controller )
  return new Handlebars.SafeString( morph.outerHTML() )

# tag
# ---
#
# Render an arbitrary tag in-place, allowing all of MooTools's sexy
# selector-to-element business.
#
# Example:
#
#     {{ tag "script[src='/lolcats.js']" }}
#
Handlebars.registerHelper "tag", (tag, options) ->
  return new Handlebars.SafeString( ( new Element( tag ) ).outerHTML )

# list
# ----
#
# Render all elements of a ListController. Any element events defined
# by the subcontroller will be attached to the list wrapper element as relay
# events. This is significantly faster than attaching events to every list
# item's elements individually.
#
Handlebars.registerHelper "list", (wrapperSelector, options) ->
  unless typeOf( @collection ) is "array"
    throw new Error "You can only use the \"list\" Handlebars helper in a ListController template."

  unless options
    options = wrapperSelector
    wrapperSelector = "div"

  # Ensure that the selector is unique
  if wrapperSelector.match( /#\w|\[id=/ )
    wrapperSelector += "[data-uuid='#{Rickshaw.uuid()}']"
  else
    wrapperSelector += "##{Rickshaw.uuid()}"
  @_listWrapperSelector = wrapperSelector
  splitWrapperTag = ( new Element( wrapperSelector ) ).outerHTML.match( /(<\w+[^>]+>)(<\/\w+>)/ )
  @_listMetamorph = new Rickshaw.Metamorph( this )

  html = []
  html.push( splitWrapperTag[1] )
  html.push( @_listMetamorph.startMarkerTag() )
  @collection.each (model) => html.push( this._setupListItemController( model ).outerHTML() )
  html.push( @_listMetamorph.endMarkerTag() )
  html.push( splitWrapperTag[2] )
  return new Handlebars.SafeString html.join( "" )
