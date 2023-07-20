import truncate_tables from require "lapis.spec.db"

import Application from require "lapis"
import mock_action from require "lapis.spec.request"

import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

import capture_errors from require "lapis.application"

factory = require "spec.factory"

wrap = (fn) ->
  capture_errors {
    on_error: => error table.concat @errors, ","
    fn
  }

describe "lapis.exceptions.flow", ->
  ExceptionFlow = require "lapis.exceptions.flow"

  before_each ->
    truncate_tables ExceptionRequests, ExceptionTypes

  it "exception_requests", ->
    mock_action Application, wrap =>
      ExceptionFlow(@)\exception_types!
      assert.same 1, @page
      assert.same {}, @exception_types

    mock_action Application, "/", {
      get: {
        status: "resolved"
        page: "2"
      }
    }, wrap =>
      ExceptionFlow(@)\exception_types!
      assert.same 2, @page
      assert.same {}, @exception_types

  it "exception_types", ->
    et = factory.ExceptionTypes!

    mock_action Application, "/", {
      get: {
        exception_type_id: et.id
      }
    }, wrap =>
      ExceptionFlow(@)\exception_requests!
      assert.same 1, @page
      assert.same {}, @exception_requests

    mock_action Application, "/", {
      get: {
        exception_type_id: et.id
        page: "2"
      }
    }, wrap =>
      ExceptionFlow(@)\exception_requests!
      assert.same 2, @page
      assert.same {}, @exception_requests


  it "find_exception_type", ->
    et = factory.ExceptionTypes!

    mock_action Application, "/", {
      get: {
        exception_type_id: et.id
      }
    }, wrap =>
      ExceptionFlow(@)\find_exception_type!
      assert.truthy @exception_type


  describe "update_exception", ->
    it "update_status", ->
      et = factory.ExceptionTypes!

      mock_action Application, "/", {
        get: {
          exception_type_id: et.id
          action: "update_status"
          status: "ignored"
        }
      }, wrap =>
        ExceptionFlow(@)\update_exception!

      et\refresh!
      assert.same ExceptionTypes.statuses.ignored, et.status

    it "delete", ->
      er = factory.ExceptionRequests!
      et = er\get_exception_type!

      mock_action Application, "/", {
        get: {
          exception_type_id: et.id
          action: "delete"
        }
      }, wrap =>
        ExceptionFlow(@)\update_exception!

      -- deletes everything
      assert.nil ExceptionTypes\find et.id
      assert.nil ExceptionRequests\find er.id

