(function() {
  describe("Rickshaw.Model", function() {
    return describe("Instantiation", function() {
      beforeEach(function() {
        return this.Todo = new Class({
          Extends: Rickshaw.Model
        });
      });
      describe("With no data", function() {
        beforeEach(function() {
          return this.todo = new this.Todo();
        });
        it("Has no data", function() {
          return expect(this.todo.data).toEqual({});
        });
        it("Sets data", function() {
          this.todo.set("foo", "bar");
          return expect(this.todo.data).toEqual({
            "foo": "bar"
          });
        });
        return it("Gets undefined data", function() {
          return expect(this.todo.get("foo")).toBeUndefined();
        });
      });
      describe("With data", function() {
        return beforeEach(function() {
          return this.todo = new this.Todo({
            id: 123,
            foo: "bar",
            baz: true
          });
        });
      });
      return describe("With data and no id property", function() {
        return beforeEach(function() {
          return this.todo = new this.Todo({
            foo: "bar",
            baz: true
          });
        });
      });
    });
  });
}).call(this);
