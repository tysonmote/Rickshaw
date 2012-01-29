require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "Rickshaw.Metamorph", ->
  beforeEach setupCustomMatchers

  describe "with no sibling metamorphs", ->
    beforeEach ->
      @morph = new Rickshaw.Metamorph("
        <div class='rad'>You betcha.</div>
        <div class='neat'>
          <div class='super'>Tubular.</div>
          <span class='cool'>Nested, yo.</span>
        </div>
      ")
      $( "test" ).set "html", "<p>Already here.</p>"
      @morph.inject $( "test" )

    it "returns outerHTML", ->
      expect( @morph.outerHTML() ).toMatch( /<script id='metamorph-\d+-start' type='text\/x-placeholder'><\/script>/ )
      expect( @morph.outerHTML() ).toMatch( /<script id='metamorph-\d+-end' type='text\/x-placeholder'><\/script>/ )

    it "renders to an element", ->
      expect( $$( "#test > .rad" ).length ).toBe( 1 )
      expect( $( "test" ).innerHTML ).toMatch( /<span class="cool">Nested, yo\.<\/span>/ )

    it "doesn't affect the other contents of the element it is rendered to", ->
      expect( $$( "#test > p" ).length ).toBe( 1 )

    it "can change its HTML", ->
      @morph.set "html", "<b class='blink'>OMG</b>"
      expect( $$( "#test > .rad" ).length ).toBe( 0 )
      expect( $$( "#test > .blink" ).length ).toBe( 1 )

    it "finds elements", ->
      expect( @morph.getElements( ".rad,.cool" ).length ).toBe( 2 )

    it "returns root elements", ->
      expect( @morph.rootElements().length ).toBe( 2 )
      expect( @morph.rootElements()[0] ).to

    it "finds root + descendant elements", ->
      elements = @morph.getElements( "div[class]" )
      expect( elements ).toBeInstanceOf( Elements )
      expect( elements.length ).toBe( 3 )

    it "returns start marker tag", ->
      expect( @morph.startMarkerTag() ).toMatch( /<script id='metamorph-\d+-start' type='text\/x-placeholder'><\/script>/ )

    it "returns end marker tag", ->
      expect( @morph.endMarkerTag() ).toMatch( /<script id='metamorph-\d+-end' type='text\/x-placeholder'><\/script>/ )

    it "returns start marker element", ->
      expect( @morph.startMarkerElement().tagName ).toBe( "SCRIPT" )
      expect( @morph.startMarkerElement().id ).toMatch( /metamorph-\d+-start/ )

    it "returns end marker element", ->
      expect( @morph.endMarkerElement().tagName ).toBe( "SCRIPT" )
      expect( @morph.endMarkerElement().id ).toMatch( /metamorph-\d+-end/ )

  describe "with sibling metamorphs", ->
    beforeEach ->
      # Resulting HTML is like:
      #
      #     <p></p>             (div#test child)
      #     <div#rad></div>     (morph1)
      #     <div#neat>...</div> (morph1)
      #     <p#funky></p>       (morph2)
      #
      @morph1 = new Rickshaw.Metamorph("
        <div id='rad'>You betcha.</div>
        <div id='neat'>
          <div id='lolcat'>Definitely.</div>
          <span class='cool'>Nested, yo.</span>
        </div>
      ")
      @morph2 = new Rickshaw.Metamorph("
        <p id='funky'>Right on.</p>
      ")
      $( "test" ).set "html", "<p>Already here.</p>"
      @morph1.inject $( "test" )
      @morph2.inject $( "test" )

    it "returns root elements", ->
      rootElements = @morph1.rootElements()
      expect( rootElements.length ).toBe( 2 )
      expect( rootElements[0].id ).toBe( "rad" )
      expect( rootElements[1].id ).toBe( "neat" )

    it "finds root and descendant elements matching a selector", ->
      elements = @morph1.getElements( "div[id]" )
      expect( elements ).toBeInstanceOf( Elements )
      expect( elements.length ).toBe( 3 )

    it "returns start marker tag", ->
      for morph in [@morph1, @morph2]
        expect( morph.startMarkerTag() ).toMatch( /<script id='metamorph-\d+-start' type='text\/x-placeholder'><\/script>/ )

    it "returns end marker tag", ->
      for morph in [@morph1, @morph2]
        expect( morph.endMarkerTag() ).toMatch( /<script id='metamorph-\d+-end' type='text\/x-placeholder'><\/script>/ )

    it "returns start marker element", ->
      for morph in [@morph1, @morph2]
        expect( morph.startMarkerElement().tagName ).toBe( "SCRIPT" )
        expect( morph.startMarkerElement().id ).toMatch( /metamorph-\d+-start/ )
      expect( @morph1.startMarkerElement().id ).not.toEqual( @morph2.startMarkerElement().id )

    it "returns end marker element", ->
      for morph in [@morph1, @morph2]
        expect( morph.endMarkerElement().tagName ).toBe( "SCRIPT" )
        expect( morph.endMarkerElement().id ).toMatch( /metamorph-\d+-end/ )
      expect( @morph1.endMarkerElement().id ).not.toEqual( @morph2.endMarkerElement().id )
