afterEach ->
  window.tearDownFixture()
  window.resetRickshaw()

window.resetRickshaw = ->
  console.log "RESET"
  $$("head")[0].adopt( new Element( "script[src='src/Rickshaw.js'][type='text/javascript']" ) )

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

window.tearDownFixture = ->
  $$("#rickshaw-spec-fixture").destroy()