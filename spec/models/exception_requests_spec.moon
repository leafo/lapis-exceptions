
lapis = require "lapis"
import mock_action from require "lapis.spec.request"

import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

describe "lapis.models.exception_requests", ->
  use_test_env!

  before_each ->
    truncate_tables ExceptionRequests, ExceptionTypes

  it "fetches empty exceptions", ->
    assert.same {}, ExceptionRequests\select!

  it "deletes exception type and all requests", ->
    ereq = factory.ExceptionRequests!
    assert ereq\get_exception_type!\delete!

    assert.same 0, ExceptionRequests\count!
    assert.same 0, ExceptionTypes\count!

  it "creates exception request", ->
    ereq = factory.ExceptionRequests!

    assert.same 1, ExceptionRequests\count!
    assert.same 1, ExceptionTypes\count!

    assert.truthy ereq.msg
    assert.truthy ereq.trace

    assert.nil ereq.path
    assert.nil ereq.ip
    assert.nil ereq.method

    etype = ereq\get_exception_type!
    assert.truthy etype

    reqs = etype\get_exception_requests!
    assert.same 1, #reqs

  it "creates exception request with bad utf8", ->
    bad_str = "#{string.char 0xf2}#{string.char 0xe0}#{string.char 0xea}#{string.char 0xe6}"

    session = require "lapis.session"

    ereq = factory.ExceptionRequests {
      msg: "message:#{bad_str}"
      trace: "trace:#{bad_str}"
      req: {
        session: setmetatable {}, { __index: {} }
        req: {
          method: "GET#{bad_str}"
          remote_addr: "1.#{bad_str}.2"
          referer: "http://ref#{bad_str}"
          request_uri: "http://example#{bad_str}"
          headers: {}
          parsed_url: {
            path: "/test/#{bad_str}"
          }
        }

      }
    }

    etype = ereq\get_exception_type!
    assert.same "message:<F2><E0><EA><E6>", etype.label

    assert.same "message:<F2><E0><EA><E6>", ereq.msg
    assert.same "GET<F2><E0><EA><E6>", ereq.method
    assert.same "http://ref<F2><E0><EA><E6>", ereq.referer
    assert.same "/test/<F2><E0><EA><E6>", ereq.path
    assert.same "trace:<F2><E0><EA><E6>", ereq.trace
    assert.same "http://example<F2><E0><EA><E6>", ereq.data.request_uri


  it "creates an exception requests from a mocked lapis requst", ->
    ereq = mock_action lapis.Application, "/hello-world?cool=zone&bad_str=\0\1hf", =>
      @params.bad_str2 = "#{string.char 0}#{string.char 0xe0}"
      factory.ExceptionRequests req: @

    assert.same "/hello-world", ereq.path
    assert.same "127.0.0.1", ereq.ip
    assert.same "GET", ereq.method

    data = ereq\get_data!
    assert.same {
      request_uri: "/hello-world?cool=zone&bad_str=%00%01hf"
      headers: {
        host: "localhost"
      }
      params: {
        cool: "zone"
        splat: "hello-world"
        bad_str: "<0><1>hf"
        bad_str2: "<0><E0>"
      }
      session: { }
    }, data

  describe "with email", ->
    local last_email
    config = require "lapis.config"

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



