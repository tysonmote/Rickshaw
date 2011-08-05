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
      Rickshaw.refreshTemplates()
      setupFixture( "templates/custom" )
      
      Rickshaw.templateRegex = /Rad-([^-]+)-template/
      Rickshaw.templatePrefix = "Rad"
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates ).toEqual({
        Other: "{{foo}}",
        Rickshaw: "{{foo}}",
      })
    
    it "Clears out templates on refresh", ->
      Rickshaw.refreshTemplates()
      setupFixture( "templates/custom" )
      
      Rickshaw.templatePrefix = "OMG"
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates ).toEqual({})
      