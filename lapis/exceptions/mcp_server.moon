json = require "cjson.safe"
db = require "lapis.db"

import McpServer from require "lapis.mcp.server"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"
import preload from require "lapis.db.model"

types = require "lapis.validate.types"

as_array = (t) ->
  setmetatable t, json.array_mt

format_group = (et) ->
  {
    id: et.id
    label: et.label
    count: et.count
    status: ExceptionTypes.statuses\to_name et.status
    created_at: et.created_at
    last_seen_at: et.last_seen_at
  }

format_exception = (r) ->
  out = {
    id: r.id
    group_id: r.exception_type_id
    msg: r.msg
    trace: r.trace
    path: r.path
    method: r.method
    ip: r.ip
    referer: r.referer
    created_at: r.created_at
  }

  data = r\get_data!
  if data and next data
    out.data = data

  out

class ExceptionsMcpServer extends McpServer
  @server_name: "lapis-exceptions"
  @server_version: "1.0.0"
  @instructions: [[Query and manage application exceptions tracked in PostgreSQL. Exception groups are normalized error messages that aggregate individual exceptions.]]

  @add_tool {
    name: "list_exception_groups"
    description: "List exception groups with occurrence counts. Supports filtering and pagination."
    inputShape: types.shape {
      ids: types.array_of(types.db_id)\describe("array of group IDs")\is_optional!
      status: types.db_enum(ExceptionTypes.statuses)\describe("filter by status")\is_optional!
      search: types.trimmed_text\describe("full-text search on labels")\is_optional!
      search_path: types.trimmed_text\describe("filter by request path substring")\is_optional!
      since: types.trimmed_text\describe("seen within interval, e.g. '24 hours'")\is_optional!
      sort: types.one_of({"recent", "oldest", "count", "id"})\describe("sort order")\is_optional!
      page: types.db_id\describe("page number")\is_optional!
      limit: types.db_id\describe("results per page")\is_optional!
    }
  }, (params) =>
    clause = db.clause {
      id: if params.ids and #params.ids > 0
        db.list params.ids

      status: params.status

      if params.search
        {"label @@ plainto_tsquery(?)", params.search}

      if params.search_path
        {
          "exists (select 1 from exception_requests where exception_requests.exception_type_id = exception_types.id and path like ?)"
          "%" .. params.search_path .. "%"
        }

      if params.since
        {"last_seen_at >= now() - ?::interval", params.since}
    }, prefix: "where", allow_empty: true

    order = switch params.sort
      when "oldest" then "ORDER BY last_seen_at ASC"
      when "count" then "ORDER BY count DESC"
      when "id" then "ORDER BY id ASC"
      else "ORDER BY last_seen_at DESC"

    per_page = params.limit or 50
    page = params.page or 1
    pager = ExceptionTypes\paginated "? #{order}", clause, {:per_page}
    results = pager\get_page page

    as_array [format_group et for et in *results]

  @add_tool {
    name: "list_exceptions"
    description: "List individual exceptions. Optionally filter by group."
    inputShape: types.shape {
      group_id: types.db_id\describe("filter to exceptions in this group")\is_optional!
      page: types.db_id\describe("page number")\is_optional!
      limit: types.db_id\describe("results per page")\is_optional!
    }
  }, (params) =>
    clause = db.clause {
      exception_type_id: params.group_id
    }, prefix: "where", allow_empty: true

    per_page = params.limit or 30
    page = params.page or 1
    pager = ExceptionRequests\paginated "? order by created_at desc", clause, {
      :per_page
      prepare_results: (ereqs) ->
        preload ereqs, "exception_type"
        ereqs
    }

    as_array [format_exception r for r in *pager\get_page page]

  @add_tool {
    name: "show_exception_group"
    description: "Show one exception group with its 5 most recent exceptions."
    inputShape: types.shape {
      group_id: types.db_id\describe "exception group ID"
    }
  }, (params) =>
    et = ExceptionTypes\find params.group_id
    return nil, "Exception group not found: #{params.group_id}" unless et

    recent = ExceptionRequests\select "where exception_type_id = ? order by created_at desc limit 5", et.id

    group = format_group et
    group.recent_exceptions = as_array [format_exception r for r in *recent]
    group

  @add_tool {
    name: "create_exception"
    description: "Create an exception. It will be auto-grouped by normalized message."
    inputShape: types.shape {
      message: types.trimmed_text\describe "error message"
      trace: types.trimmed_text\describe("stack trace")\is_optional!
      path: types.trimmed_text\describe("request path")\is_optional!
      method: types.trimmed_text\describe("HTTP method")\is_optional!
      ip: types.trimmed_text\describe("IP address")\is_optional!
      data: types.table\describe("additional data")\is_optional!
    }
  }, (params) =>
    ereq, new_group = ExceptionRequests\create {
      msg: params.message
      trace: params.trace
      path: params.path
      method: params.method
      ip: params.ip
      data: params.data or {}
    }

    etype = ExceptionTypes\find ereq.exception_type.id

    {
      exception_group: format_group etype
      exception: format_exception ereq
      new_group: new_group
    }

  @add_tool {
    name: "update_exception_group"
    description: "Update the status of an exception group."
    inputShape: types.shape {
      group_id: types.db_id\describe "exception group ID"
      status: types.db_enum(ExceptionTypes.statuses)\describe "new status"
    }
  }, (params) =>
    et = ExceptionTypes\find params.group_id
    return nil, "Exception group not found: #{params.group_id}" unless et

    et\update status: params.status
    format_group et

  @add_tool {
    name: "delete_exception_group"
    description: "Delete an exception group. Use exceptions_only to keep the group but clear its exceptions."
    inputShape: types.shape {
      group_id: types.db_id\describe "exception group ID"
      exceptions_only: types.boolean\describe("only delete exceptions, keep the group")\is_optional!
    }
  }, (params) =>
    et = ExceptionTypes\find params.group_id
    return nil, "Exception group not found: #{params.group_id}" unless et

    if params.exceptions_only
      db.delete "exception_requests", exception_type_id: et.id
      et\update count: 0
      "Deleted all exceptions for group ##{et.id}, count reset to 0."
    else
      et\delete!
      "Deleted exception group ##{et.id} and all associated exceptions."
