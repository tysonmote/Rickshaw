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
    throw name: "ArgumentError", message: "You must supply a controller instance to \"subController\"."
  return new Handlebars.SafeString this._setupSubcontroller( controller )

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
  return new Handlebars.SafeString ( new Element( tag ) ).outerHTML

# list
# ----
#
# Render all elements of a Rickshaw.ListController
Handlebars.registerHelper "list", (options) ->
  unless typeOf( @collection ) is "array"
    throw name: "HandlebarsError", message: "You can only use the \"list\" Handlebars helper in a Rickshaw.ListController template."
  html = @collection.map (model) => this._setupSubcontrollerWithModel( model )
  return new Handlebars.SafeString html.join( "\n" )