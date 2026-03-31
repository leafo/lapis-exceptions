import truncate_tables from require "lapis.spec.db"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

factory = require "spec.factory"

ExceptionsMcpServer = require "lapis.exceptions.mcp_server"

describe "lapis.exceptions.mcp_server", ->
  local server

  before_each ->
    truncate_tables ExceptionRequests, ExceptionTypes
    server = ExceptionsMcpServer!
    server\skip_initialize!

  it "lists all tools", ->
    tools = server\get_enabled_tools!
    names = [t.name for t in *tools]
    table.sort names

    assert.same {
      "create_exception"
      "delete_exception_group"
      "list_exception_groups"
      "list_exceptions"
      "show_exception_group"
      "update_exception_group"
    }, names

  describe "list_exception_groups", ->
    it "returns empty list", ->
      result = server\execute_tool "list_exception_groups", {}
      assert.same {}, result

    it "returns groups", ->
      factory.ExceptionRequests msg: "error one"
      factory.ExceptionRequests msg: "error two"

      result = server\execute_tool "list_exception_groups", {}
      assert.same 2, #result
      assert.truthy result[1].id
      assert.truthy result[1].label
      assert.truthy result[1].status
      assert.same "number", type result[1].count

    it "filters by status", ->
      factory.ExceptionTypes label: "resolved error", status: ExceptionTypes.statuses.resolved
      factory.ExceptionTypes label: "default error"

      result = server\execute_tool "list_exception_groups", status: "resolved"
      assert.same 1, #result
      assert.same "resolved", result[1].status

    it "filters by ids", ->
      et1 = factory.ExceptionTypes!
      et2 = factory.ExceptionTypes!
      et3 = factory.ExceptionTypes!

      result = server\execute_tool "list_exception_groups", ids: {et1.id, et3.id}
      assert.same 2, #result

    it "paginates", ->
      for i=1,5
        factory.ExceptionTypes!

      result = server\execute_tool "list_exception_groups", limit: 2, page: 1
      assert.same 2, #result

  describe "list_exceptions", ->
    it "returns empty list", ->
      result = server\execute_tool "list_exceptions", {}
      assert.same {}, result

    it "returns exceptions", ->
      factory.ExceptionRequests!
      result = server\execute_tool "list_exceptions", {}
      assert.same 1, #result
      assert.truthy result[1].id
      assert.truthy result[1].group_id
      assert.truthy result[1].msg

    it "filters by group_id", ->
      er1 = factory.ExceptionRequests msg: "first error"
      er2 = factory.ExceptionRequests msg: "second error"

      result = server\execute_tool "list_exceptions", group_id: er1.exception_type_id
      assert.same 1, #result
      assert.same er1.exception_type_id, result[1].group_id

  describe "show_exception_group", ->
    it "returns group with recent exceptions", ->
      er = factory.ExceptionRequests!
      et = ExceptionTypes\find er.exception_type_id

      result = server\execute_tool "show_exception_group", group_id: et.id
      assert.same et.id, result.id
      assert.same et.label, result.label
      assert.truthy result.recent_exceptions
      assert.same 1, #result.recent_exceptions
      assert.same er.id, result.recent_exceptions[1].id

    it "returns error for missing group", ->
      result, err = server\execute_tool "show_exception_group", group_id: 999
      assert.nil result
      assert.truthy err\match "not found"

  describe "create_exception", ->
    it "creates a new exception", ->
      result = server\execute_tool "create_exception", message: "test error happened"
      assert.truthy result.exception_group
      assert.truthy result.exception
      assert.truthy result.new_group
      assert.truthy result.exception_group.id
      assert.truthy result.exception.id

      assert.same 1, ExceptionRequests\count!
      assert.same 1, ExceptionTypes\count!

    it "groups duplicate errors", ->
      server\execute_tool "create_exception", message: "same error"
      server\execute_tool "create_exception", message: "same error"

      assert.same 2, ExceptionRequests\count!
      assert.same 1, ExceptionTypes\count!

      et = ExceptionTypes\select![1]
      assert.same 2, et.count

  describe "update_exception_group", ->
    it "updates status", ->
      et = factory.ExceptionTypes!
      result = server\execute_tool "update_exception_group", group_id: et.id, status: "ignored"
      assert.same "ignored", result.status

      et\refresh!
      assert.same ExceptionTypes.statuses.ignored, et.status

    it "returns error for missing group", ->
      result, err = server\execute_tool "update_exception_group", group_id: 999, status: "resolved"
      assert.nil result
      assert.truthy err\match "not found"

  describe "delete_exception_group", ->
    it "deletes group and exceptions", ->
      er = factory.ExceptionRequests!
      et = ExceptionTypes\find er.exception_type_id

      result = server\execute_tool "delete_exception_group", group_id: et.id
      assert.truthy result\match "Deleted exception group"
      assert.same 0, ExceptionTypes\count!
      assert.same 0, ExceptionRequests\count!

    it "deletes only exceptions when exceptions_only", ->
      er = factory.ExceptionRequests!
      et = ExceptionTypes\find er.exception_type_id

      result = server\execute_tool "delete_exception_group", group_id: et.id, exceptions_only: true
      assert.truthy result\match "count reset to 0"
      assert.same 1, ExceptionTypes\count!
      assert.same 0, ExceptionRequests\count!

      et\refresh!
      assert.same 0, et.count

    it "returns error for missing group", ->
      result, err = server\execute_tool "delete_exception_group", group_id: 999
      assert.nil result
      assert.truthy err\match "not found"
