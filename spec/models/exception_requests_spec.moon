config = require "lapis.config"

lapis = require "lapis"
import mock_action from require "lapis.spec.request"

config "test", ->
  postgres {
    database: "lapis_exceptions_test"
  }

import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

describe "lapis.models.exception_requests", ->
  use_test_env!
  setup require("spec.helpers").create_db

  before_each ->
    import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"
    truncate_tables ExceptionRequests, ExceptionTypes

  it "creates exception type", ->
    ereq = factory.ExceptionRequests!
    assert.truthy ereq.msg
    assert.truthy ereq.trace

    assert.nil ereq.path
    assert.nil ereq.ip
    assert.nil ereq.method

    etype = ereq\get_exception_type!
    assert.truthy etype

    reqs = etype\get_exception_requests!
    assert.same 1, #reqs

  it "creates an exception requests from a mocked lapis requst", ->
    ereq = mock_action lapis.Application, "/hello-world?cool=zone", =>
      factory.ExceptionRequests req: @

    assert.same "/hello-world", ereq.path
    assert.same "127.0.0.1", ereq.ip
    assert.same "GET", ereq.method

    data = ereq\get_data!
    assert.same {
      cmd_url: "/hello-world?cool=zone"
      headers: {
        host: "localhost"
      }
      params: {
        cool: "zone"
        splat: "hello-world"
      }
      session: { }
    }, data

  describe "with email", ->
    local last_email

    before_each ->
      last_email = nil
      config.get!.admin_email = "leafo@example.com"
      package.loaded["helpers.email"] = {
        send_email: (...) ->
          last_email = { ... }
      }

    after_each ->
      config.get!.admin_email = nil
      package.loaded["helpers.email"] = nil

    it "sends exception email", ->
      factory.ExceptionRequests req: @
      assert.truthy last_email
      email, subject, body, opts = unpack last_email
      assert.same "leafo@example.com", email

    it "sends exception email for request", ->
      ereq = mock_action lapis.Application, "/hello-world", =>
        factory.ExceptionRequests req: @

      assert.truthy last_email

      email, subject, body, opts = unpack last_email
      assert.same "leafo@example.com", email
      assert.same {html: true}, opts



