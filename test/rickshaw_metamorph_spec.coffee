describe "Rickshaw.Metamorph", ->
  beforeEach resetRickshaw

  describe "#findView()", ->
    beforeEach ->
      @Todo = new Model()
      @todo = new @Todo({})
      Rickshaw.addTemplate( "todo", "<p>Rad.</p>" )
      @TodoController = new Controller(
        Template: "todo"
        Events: p: click: -> false
      )
      @todoController = new @TodoController( @todo, $( "test" ) )

    it "returns the correct View instance for an element + event function", ->
      element = $( "test" ).getElement( "p" )
      event = @todoController._boundEvents.p.click
      expect( Rickshaw.Metamorph.findView( element, event, "p", "click" ) ).to.be.instanceOf( View )
      expect( Rickshaw.Metamorph.findView( element, event, "p", "click" ).controller ).to.be( @todoController )
      expect( -> Rickshaw.Metamorph.findView( element, (->), "p", "click" ) )
        .to.throwException( /reached <body> without finding a matching Metamorph/ )
      expect( -> Rickshaw.Metamorph.findView( element, event, "404", "click" ) )
        .to.throwException( /reached <body> without finding a matching Metamorph/ )
      expect( -> Rickshaw.Metamorph.findView( element, event, "p", "404" ) )
        .to.throwException( /reached <body> without finding a matching Metamorph/ )

  describe "with no sibling metamorphs", ->
    beforeEach ->
      @fakeView = {}
      @morph = new Rickshaw.Metamorph( @fakeView, "
        <div class='rad'>You betcha.</div>
        <div class='neat'>
          <div class='super'>Tubular.</div>
          <span class='cool'>Nested, yo.</span>
        </div>
      ")
      $( "test" ).set "html", "<p>Already here.</p>"
      @morph.inject $( "test" )

    it "returns outerHTML", ->
      expect( @morph.outerHTML() ).to.match( /<script id='metamorph-\d+-start' type='text\/x-placeholder'><\/script>/ )
      expect( @morph.outerHTML() ).to.match( /<script id='metamorph-\d+-end' type='text\/x-placeholder'><\/script>/ )

    it "renders to an element", ->
      expect( $$( "#test > .rad" ).length ).to.be( 1 )
      expect( $( "test" ).innerHTML ).to.match( /<span class="cool">Nested, yo\.<\/span>/ )

    it "doesn't affect the other contents of the element it is rendered to", ->
      expect( $$( "#test > p" ).length ).to.be( 1 )

    it "can change its HTML", ->
      @morph.setHTML "<b class='blink'>OMG</b>"
      expect( $$( "#test > .rad" ).length ).to.be( 0 )
      expect( $$( "#test > .blink" ).length ).to.be( 1 )

    it "finds elements", ->
      expect( @morph.getElements( ".rad,.cool" ).length ).to.be( 2 )

    it "returns root elements", ->
      expect( @morph.rootElements().length ).to.be( 2 )
      expect( @morph.rootElements()[0] ).to

    it "finds root + descendant elements", ->
      elements = @morph.getElements( "div[class]" )
      expect( elements ).to.be.instanceOf( Elements )
      expect( elements.length ).to.be( 3 )

    it "returns start marker tag", ->
      expect( @morph.startMarkerTag() ).to.match( /<script id='metamorph-\d+-start' type='text\/x-placeholder'><\/script>/ )

    it "returns end marker tag", ->
      expect( @morph.endMarkerTag() ).to.match( /<script id='metamorph-\d+-end' type='text\/x-placeholder'><\/script>/ )

    it "returns start marker element", ->
      expect( @morph.startMarkerElement().tagName ).to.be( "SCRIPT" )
      expect( @morph.startMarkerElement().id ).to.match( /metamorph-\d+-start/ )

    it "returns end marker element", ->
      expect( @morph.endMarkerElement().tagName ).to.be( "SCRIPT" )
      expect( @morph.endMarkerElement().id ).to.match( /metamorph-\d+-end/ )

    it "stores the view instance on the start marker", ->
      expect( @morph.startMarkerElement().retrieve( "rickshaw-view" ) ).to.be( @fakeView )

  describe "with sibling metamorphs", ->
    beforeEach ->
      # Resulting HTML is like:
      #
      #     <p></p>             (div#test child)
      #     <div#rad></div>     (morph1)
      #     <div#neat>...</div> (morph1)
      #     <p#funky></p>       (morph2)
      #
      @fakeView1 = {}
      @morph1 = new Rickshaw.Metamorph( @fakeView1, "
        <div id='rad'>You betcha.</div>
        <div id='neat'>
          <div id='lolcat'>Definitely.</div>
          <span class='cool'>Nested, yo.</span>
        </div>
      ")
      @fakeView2 = {}
      @morph2 = new Rickshaw.Metamorph( @fakeView2, "
        <p id='funky'>Right on.</p>
      ")
      $( "test" ).set "html", "<p>Already here.</p>"
      @morph1.inject $( "test" )
      @morph2.inject $( "test" )

    it "returns root elements", ->
      rootElements = @morph1.rootElements()
      expect( rootElements.length ).to.be( 2 )
      expect( rootElements[0].id ).to.be( "rad" )
      expect( rootElements[1].id ).to.be( "neat" )

    it "finds root and descendant elements matching a selector", ->
      elements = @morph1.getElements( "div[id]" )
      expect( elements ).to.be.instanceOf( Elements )
      expect( elements.length ).to.be( 3 )

    it "returns start marker tag", ->
      for morph in [@morph1, @morph2]
        expect( morph.startMarkerTag() ).to.match( /<script id='metamorph-\d+-start' type='text\/x-placeholder'><\/script>/ )

    it "returns end marker tag", ->
      for morph in [@morph1, @morph2]
        expect( morph.endMarkerTag() ).to.match( /<script id='metamorph-\d+-end' type='text\/x-placeholder'><\/script>/ )

    it "returns start marker element", ->
      for morph in [@morph1, @morph2]
        expect( morph.startMarkerElement().tagName ).to.be( "SCRIPT" )
        expect( morph.startMarkerElement().id ).to.match( /metamorph-\d+-start/ )
      expect( @morph1.startMarkerElement().id ).not.to.eql( @morph2.startMarkerElement().id )

    it "returns end marker element", ->
      for morph in [@morph1, @morph2]
        expect( morph.endMarkerElement().tagName ).to.be( "SCRIPT" )
        expect( morph.endMarkerElement().id ).to.match( /metamorph-\d+-end/ )
      expect( @morph1.endMarkerElement().id ).not.to.eql( @morph2.endMarkerElement().id )

    it "stores the controller instance on the start marker", ->
      expect( @morph1.startMarkerElement().retrieve( "rickshaw-view" ) ).to.be( @fakeView1 )
      expect( @morph2.startMarkerElement().retrieve( "rickshaw-view" ) ).to.be( @fakeView2 )
