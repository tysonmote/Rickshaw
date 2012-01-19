require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe( "Rickshaw", ->
  describe( "UUIDs", ->
    UUID_REGEX = /^rickshaw-[0-9a-f]{8}-[0-9a-f]{8}$/

    it( "Generates unique UUIDs", ->
      expect( Rickshaw.uuid() ).toMatch( UUID_REGEX )
      expect( Rickshaw.uuid() == Rickshaw.uuid() ).toBe( false )
    )

    it( "Registers objects and finds", ->
      object = {}
      Rickshaw.register( object )
      expect( object._uuid ).toMatch( UUID_REGEX )
      expect( Rickshaw.get( object._uuid ) ).toBe( object )
    )
  )
)
