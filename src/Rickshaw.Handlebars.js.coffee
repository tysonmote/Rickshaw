# Handlebars
# ==========
#
# Handlebars helpers for Rickshaw. All helper functions are bound to the
# Controller / ListController instance being rendered. The View / ListView
# instance can be accessed via `options.data.view`.

# subController
# -------------
#
# Render the given Controller / ListController instance in-place.
#
Handlebars.registerHelper "subController", (controller, options) ->
  # TODO: Cleanup the arguments handling here
  unless arguments.length is 2
    throw new Error "You must supply a controller instance to \"subController\"."
  unless controller
    throw new Error "Invalid controller passed to the subController template helper."
  if this is controller
    throw new Error "You can't recursively render a controller inside of itself."

  view = options.data.view._subview( controller )
  return new Handlebars.SafeString( view.placeholderHTML() )

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
# For ListControllers, render the list of models in-place inside the given
# wrapper tag. Eg.
#
#     {{ list "div.my_stuff" }}
#
Handlebars.registerHelper "list", (wrapperSelector, options) ->
  unless Rickshaw.typeOf( this ) is "ListController"
    throw new Error "You can only use the \"list\" Handlebars helper in a ListController. This is a(n) #{Rickshaw.typeOf( this ) or typeOf( this )}"

  if typeof wrapperSelector is "object"
    options = wrapperSelector
    wrapperSelector = "div"

  listView = options.data.view._listview( wrapperSelector )
  return new Handlebars.SafeString( listView.placeholderHTML() )

Handlebars.registerHelper "debug", ->
  args = Array.from( arguments )
  options = args.pop()
  console.log args, options
