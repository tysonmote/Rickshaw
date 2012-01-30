# Rickshaw.Handlebars
# ===================
#
# Handlebars helpers for Rickshaw.

# subController
# -------------
#
# Render a Rickshaw.Controller / Rickshaw.ListController instance in-place.
#
Handlebars.registerHelper "subController", (controller, options) ->
  unless arguments.length is 2
    throw new Error "You must supply a controller instance to \"subController\"."
  unless controller
    throw new Error "Invalid controller passed to the subController template helper."
  return new Handlebars.SafeString( this._setupSubcontroller( controller ) )

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
# Render all elements of a Rickshaw.ListController
Handlebars.registerHelper "list", (options) ->
  unless typeOf( @collection ) is "array"
    throw new Error "You can only use the \"list\" Handlebars helper in a Rickshaw.ListController template."
  html = []
  @_listMetamorph = new Rickshaw.Metamorph( this )
  html.push( @_listMetamorph.startMarkerTag() )
  @collection.each (model) => html.push( this._setupListItemController( model ) )
  html.push( @_listMetamorph.endMarkerTag() )
  return new Handlebars.SafeString html.join( "\n" )
