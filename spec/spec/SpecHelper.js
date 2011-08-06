(function() {
  afterEach(function() {
    window.tearDownFixture();
    return window.resetRickshaw();
  });
  window.resetRickshaw = function() {
    return $$("head")[0].adopt(new Element("script[src='src/Rickshaw.js'][type='text/javascript']"));
  };
  window.setupFixture = function(name) {
    var fixtureWrapper, url;
    url = "spec/fixtures/" + name + ".html";
    fixtureWrapper = new Element("#rickshaw-spec-fixture");
    return (new Request({
      url: url,
      async: false,
      onFailure: function(xhr) {
        $(document.body).adopt(fixtureWrapper);
        return fixtureWrapper.innerHTML = xhr.response;
      }
    })).get();
  };
  window.tearDownFixture = function() {
    return $$("#rickshaw-spec-fixture").destroy();
  };
}).call(this);
