config = require "lapis.config"
config "test", ->
  postgres {
    database: "lapis_exceptions_test"
  }

import truncate_tables from require "lapis.spec.db"
import use_test_env from require "lapis.spec"

import TestApp from require "spec.helpers"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

class App extends TestApp
  "/": =>
    json: { "hello" }

describe "lapis.exceptions.flow", ->
  use_test_env!

  before_each ->
    truncate_tables ExceptionRequests, ExceptionTypes

  it "browses exception types", ->
    App\get "/"
