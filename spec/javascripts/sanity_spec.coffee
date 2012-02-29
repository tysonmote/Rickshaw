require "/vendor/mootools-core.js"
require "/vendor/handlebars.js"
require "/vendor/metamorph.js"
require "/rickshaw.js"

describe "matchers", ->
  beforeEach setupCustomMatchers

  it "toBeEmpty", ->
    expect( [] ).toBeEmpty()
    expect( [1] ).not.toBeEmpty()

  it "toMatchArray", ->
    expect( [1, {a: "b"}] ).toMatchArray( [1, {a: "b"}] )
    expect( ["1", {a: "b"}] ).not.toMatchArray( [1, {a: "b"}] )

  it "toBeInstanceOf", ->
    expect( new Date() ).toBeInstanceOf( Date )
    expect( new Date() ).toBeInstanceOf( Object )
    expect( new Date() ).not.toBeInstanceOf( String )

  it "toThrowException", ->
    expect( -> throw new Error "OMG" ).toThrowException( /OMG/ )
    expect( -> "OMG" ).not.toThrowException( /OMG/ )
    expect( -> throw new Error "OMG" ).not.toThrowException( /ZOMG/ )
