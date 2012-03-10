describe "Expect Matchers", ->
  it "matchArray", ->
    expect( [] ).to.matchArray( [] )
    expect( [] ).to.not.matchArray( [0] )
    expect( [1, {a: "b"}] ).to.matchArray( [1, {a: "b"}] )
    expect( ["1", {a: "b"}] ).to.not.matchArray( [1, {a: "b"}] )

  it "instanceOf", ->
    expect( new Date() ).to.be.instanceOf( Date )
    expect( new Date() ).to.be.instanceOf( Object )
    expect( new Date() ).to.not.be.instanceOf( String )
