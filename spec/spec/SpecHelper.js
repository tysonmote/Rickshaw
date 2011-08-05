(function() {
  afterEach(function() {
    return window.tearDownFixture();
  });
  window.setupFixture = function(name) {
    var fixtureWrapper, url;
    url = "spec/fixtures/" + name + ".html";
    fixtureWrapper = new Element("#rickshaw-spec-fixture");
    return (new Request({
      url: url,
      async: false,
      onFailure: function(xhr) {
        $(document.body).adopt(fixtureWrapper);
        fixtureWrapper.innerHTML = xhr.response;
        return console.log(fixtureWrapper);
      }
    })).get();
  };
  window.tearDownFixture = function() {
    return $$("#rickshaw-spec-fixture").destroy();
  };
}).call(this);
