lapis = require "lapis"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

describe "lapis.models.exception_requests", ->
  before_each ->
    truncate_tables ExceptionRequests, ExceptionTypes

  it "creates exception type", ->
    etype = factory.ExceptionTypes!
    assert.truthy etype

  it "creates exception type with bad unicode", ->
    etype = factory.ExceptionTypes {
      label: "/hello/world#{string.char 0xf2}#{string.char 0xe0}#{string.char 0xea}#{string.char 0xe6}"
    }
    assert.truthy etype
    assert.same "/hello/world<F2><E0><EA><E6>", etype.label

  describe "should_notify", ->
    it "should notify for a new exception", ->
      etype = ExceptionTypes\find_or_create "hello world"
      assert.true etype\should_notify!

    it "should not notify for a recent exception", ->
      ExceptionTypes\find_or_create "hello world"
      etype = ExceptionTypes\find_or_create "hello world"
      assert.false etype\should_notify!

    it "should always notify for a exception that was resolved", ->
      ExceptionTypes\find_or_create "hello world"
      etype = ExceptionTypes\find_or_create "hello world"
      etype\update status: ExceptionTypes.statuses.resolved
      assert.true etype\should_notify!

    it "should never notify an ignored exception", ->
      etype = ExceptionTypes\find_or_create "hello world"
      etype\update status: ExceptionTypes.statuses.resolved
      assert.true etype\should_notify!




