describe "Rickshaw", ->
  describe "Templates", ->
    it "Loads templates and detects names", ->
      setupFixture( "templates/simple" )
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates.Message({
        message: "a"
      })).toEqual("\n  <span>a</span>\n")
      
      expect( Rickshaw.Templates.Comment_Thing({
        comment: "a"
      })).toEqual("\n  a\n")
      
    it "Allows overiding the prefix and regex", ->
      Rickshaw.refreshTemplates()
      setupFixture( "templates/custom" )
      
      Rickshaw.templateRegex = /Rad-([^-]+)-template/
      Rickshaw.templatePrefix = "Rad"
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates.Other({
        foo: "a"
      })).toEqual("a")
      
      expect( Rickshaw.Templates.Rickshaw({
        foo: "a"
      })).toEqual("a")
    
    it "Clears out templates on refresh", ->
      Rickshaw.refreshTemplates()
      setupFixture( "templates/custom" )
      
      Rickshaw.templatePrefix = "OMG"
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates ).toEqual({})
      