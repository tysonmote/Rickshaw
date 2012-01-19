# Extensions to Handlebars for Rickshaw.

Handlebars.registerHelper( "subController", (controller, tag, options) ->
  if typeof( tag ) == "object"
    options = tag
    tag = "div"
  tag += ".rickshaw-subcontroller.rickshaw-unrendered"
  tag += "[data-uuid='#{controller._uuid}']"
  return new Handlebars.SafeString( ( new Element( tag ) ).outerHTML )
)

Handlebars.registerHelper( "tag", (tag, options) ->
  return new Handlebars.SafeString( ( new Element( tag ) ).outerHTML )
)
