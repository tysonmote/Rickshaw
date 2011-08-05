(function() {
  describe("Rickshaw", function() {
    return describe("template loading", function() {
      return it("should load templates and detect their names", function() {
        setupFixture("simple_templates");
        Rickshaw.refreshTemplates();
        console.log(Rickshaw.Templates);
        return expect(Rickshaw.Templates).toEqual({
          Message: "\n  <span>{{message}}</span>\n",
          Comment_Thing: "\n  {{comment}}\n"
        });
      });
    });
  });
}).call(this);
