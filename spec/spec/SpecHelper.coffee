afterEach ->
  window.tearDownFixture()
  window.resetRickshaw()

window.resetRickshaw = ->
  $$("head")[0].adopt( new Element( "script[src='src/Rickshaw.js'][type='text/javascript']" ) )

# ============
# = Fixtures =
# ============

# The disadvantage of doing fixtures this way is that the fixture can pollute
# the global namespace easily and there's not much we can do about it. So be
# smart.
window.setupFixture = (name) ->
  url = "spec/fixtures/" + name + ".html"
  fixtureWrapper = new Element("#rickshaw-spec-fixture")
  (new Request(
    url: url
    async: false
    onFailure: (xhr) ->
      $(document.body).adopt fixtureWrapper
      fixtureWrapper.innerHTML = xhr.response
  )).get()

# Destroy the fixture HTML. Keep in mind that if the fixture has script tags,
# they can pollute the global namespace and there's not much we can do about it.
window.tearDownFixture = ->
  $$("#rickshaw-spec-fixture").destroy()
