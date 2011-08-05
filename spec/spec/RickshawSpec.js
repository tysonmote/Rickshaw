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
      return it("Allows overiding the prefix and regex", function() {
        Rickshaw.templateRegex = /Rad-([^-]+)-template/;
        Rickshaw.templatePrefix = "Rad";
        setupFixture("templates/custom");
        Rickshaw.refreshTemplates();
        return expect(Rickshaw.Templates).toEqual({
          Other: "{{foo}}",
          Rickshaw: "{{foo}}"
        });
      });
    });
  });
}).call(this);
