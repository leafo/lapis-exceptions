config = require "lapis.config"

config "test", ->
  postgres {
    database: "lapis_exceptions_test"
  }

import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

describe "lapis.exceptions.flow", ->
  use_test_env!
  setup require("spec.helpers").create_db

  before_each ->
    import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"
    truncate_tables ExceptionRequests, ExceptionTypes

  it "creates exception type", ->
    ereq = factory.ExceptionRequests!
    assert.truthy ereq.msg
    assert.truthy ereq.trace
    etype = req\get_exception_type!
    assert.truthy etype

