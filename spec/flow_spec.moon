config = require "lapis.config"
config "test", ->
  postgres {
    database: "lapis_exceptions_test"
  }

import truncate_tables from require "lapis.spec.db"
import use_test_env from require "lapis.spec"

import TestApp from require "spec.helpers"

class App extends TestApp
  "/": =>
    json: { "hello" }

describe "lapis.exceptions.flow", ->
  use_test_env!

  setup require("spec.helpers").create_db

  before_each ->
    truncate_tables ExceptionRequests, ExceptionTypes
    import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

  it "browses exception types", ->
    App\get "/"
