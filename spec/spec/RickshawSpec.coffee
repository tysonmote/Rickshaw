describe "Rickshaw", ->
  describe "Templates", ->
    it "Loads templates and detects names", ->
      setupFixture( "templates/simple" )
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates ).toEqual({
        Message: "\n  <span>{{message}}</span>\n",
        Comment_Thing: "\n  {{comment}}\n",
      })
      
    it "Allows overiding the prefix and regex", ->
      Rickshaw.templateRegex = /Rad-([^-]+)-template/
      Rickshaw.templatePrefix = "Rad"
      
      setupFixture( "templates/custom" )
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates ).toEqual({
        Other: "{{foo}}",
        Rickshaw: "{{foo}}",
      })
