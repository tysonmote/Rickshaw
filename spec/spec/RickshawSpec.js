(function() {
  describe("Rickshaw", function() {
    return describe("Templates", function() {
      it("Loads templates and detects names", function() {
        setupFixture("templates/simple");
        Rickshaw.refreshTemplates();
        return expect(Rickshaw.Templates).toEqual({
          Message: "\n  <span>{{message}}</span>\n",
          Comment_Thing: "\n  {{comment}}\n"
        });
      });
      it("Allows overiding the prefix and regex", function() {
        Rickshaw.refreshTemplates();
        setupFixture("templates/custom");
        Rickshaw.templateRegex = /Rad-([^-]+)-template/;
        Rickshaw.templatePrefix = "Rad";
        Rickshaw.refreshTemplates();
        return expect(Rickshaw.Templates).toEqual({
          Other: "{{foo}}",
          Rickshaw: "{{foo}}"
        });
      });
      return it("Clears out templates on refresh", function() {
        Rickshaw.refreshTemplates();
        setupFixture("templates/custom");
        Rickshaw.templatePrefix = "OMG";
        Rickshaw.refreshTemplates();
        return expect(Rickshaw.Templates).toEqual({});
      });
    });
  });
}).call(this);
