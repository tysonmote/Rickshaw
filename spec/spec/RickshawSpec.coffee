describe "Rickshaw", ->
  describe "Templates", ->
    it "Loads templates and detects names", ->
      setupFixture( "simple_templates" )
      Rickshaw.refreshTemplates()
      
      expect( Rickshaw.Templates ).toEqual({
        Message: "\n  <span>{{message}}</span>\n",
        Comment_Thing: "\n  {{comment}}\n",
      })
