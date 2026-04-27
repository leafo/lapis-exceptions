local json = require("cjson.safe")
local db = require("lapis.db")
local McpServer
McpServer = require("lapis.mcp.server").McpServer
local ExceptionRequests, ExceptionTypes
do
  local _obj_0 = require("lapis.exceptions.models")
  ExceptionRequests, ExceptionTypes = _obj_0.ExceptionRequests, _obj_0.ExceptionTypes
end
local preload
preload = require("lapis.db.model").preload
local types = require("lapis.validate.types")
local as_array
as_array = function(t)
  return setmetatable(t, json.array_mt)
end
local format_group
format_group = function(et)
  return {
    id = et.id,
    label = et.label,
    count = et.count,
    status = ExceptionTypes.statuses:to_name(et.status),
    created_at = et.created_at,
    last_seen_at = et.last_seen_at
  }
end
local format_exception
format_exception = function(r)
  local out = {
    id = r.id,
    group_id = r.exception_type_id,
    msg = r.msg,
    trace = r.trace,
    path = r.path,
    method = r.method,
    ip = r.ip,
    referer = r.referer,
    created_at = r.created_at
  }
  local data = r:get_data()
  if data and next(data) then
    out.data = data
  end
  return out
end
local ExceptionsMcpServer
do
  local _class_0
  local _parent_0 = McpServer
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ExceptionsMcpServer",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.server_name = "lapis-exceptions"
  self.server_version = "1.0.0"
  self.instructions = [[Query and manage application exceptions tracked in PostgreSQL. Exception groups are normalized error messages that aggregate individual exceptions.]]
  self:add_tool({
    name = "list_exception_groups",
    description = "List exception groups with occurrence counts. Supports filtering and pagination.",
    inputShape = types.shape({
      ids = types.array_of(types.db_id):describe("array of group IDs"):is_optional(),
      status = types.db_enum(ExceptionTypes.statuses):describe("filter by status"):is_optional(),
      search = types.trimmed_text:describe("full-text search on labels"):is_optional(),
      search_path = types.trimmed_text:describe("filter by request path substring"):is_optional(),
      since = types.trimmed_text:describe("seen within interval, e.g. '24 hours'"):is_optional(),
      sort = types.one_of({
        "recent",
        "oldest",
        "count",
        "id"
      }):describe("sort order"):is_optional(),
      page = types.db_id:describe("page number"):is_optional(),
      limit = types.db_id:describe("results per page"):is_optional()
    })
  }, function(self, params)
    local clause = db.clause({
      id = (function()
        if params.ids and #params.ids > 0 then
          return db.list(params.ids)
        end
      end)(),
      status = params.status,
      (function()
        if params.search then
          return {
            "label @@ plainto_tsquery(?)",
            params.search
          }
        end
      end)(),
      (function()
        if params.search_path then
          return {
            "exists (select 1 from exception_requests where exception_requests.exception_type_id = exception_types.id and path like ?)",
            "%" .. params.search_path .. "%"
          }
        end
      end)(),
      (function()
        if params.since then
          return {
            "last_seen_at >= now() - ?::interval",
            params.since
          }
        end
      end)()
    }, {
      prefix = "where",
      allow_empty = true
    })
    local order
    local _exp_0 = params.sort
    if "oldest" == _exp_0 then
      order = "ORDER BY last_seen_at ASC"
    elseif "count" == _exp_0 then
      order = "ORDER BY count DESC"
    elseif "id" == _exp_0 then
      order = "ORDER BY id ASC"
    else
      order = "ORDER BY last_seen_at DESC"
    end
    local per_page = params.limit or 50
    local page = params.page or 1
    local pager = ExceptionTypes:paginated("? " .. tostring(order), clause, {
      per_page = per_page
    })
    local results = pager:get_page(page)
    return as_array((function()
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #results do
        local et = results[_index_0]
        _accum_0[_len_0] = format_group(et)
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
  end)
  self:add_tool({
    name = "list_exceptions",
    description = "List individual exceptions. Optionally filter by group.",
    inputShape = types.shape({
      group_id = types.db_id:describe("filter to exceptions in this group"):is_optional(),
      page = types.db_id:describe("page number"):is_optional(),
      limit = types.db_id:describe("results per page"):is_optional()
    })
  }, function(self, params)
    local clause = db.clause({
      exception_type_id = params.group_id
    }, {
      prefix = "where",
      allow_empty = true
    })
    local per_page = params.limit or 30
    local page = params.page or 1
    local pager = ExceptionRequests:paginated("? order by created_at desc", clause, {
      per_page = per_page,
      prepare_results = function(ereqs)
        preload(ereqs, "exception_type")
        return ereqs
      end
    })
    return as_array((function()
      local _accum_0 = { }
      local _len_0 = 1
      local _list_0 = pager:get_page(page)
      for _index_0 = 1, #_list_0 do
        local r = _list_0[_index_0]
        _accum_0[_len_0] = format_exception(r)
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
  end)
  self:add_tool({
    name = "show_exception_group",
    description = "Show one exception group with its 5 most recent exceptions.",
    inputShape = types.shape({
      group_id = types.db_id:describe("exception group ID")
    })
  }, function(self, params)
    local et = ExceptionTypes:find(params.group_id)
    if not (et) then
      return nil, "Exception group not found: " .. tostring(params.group_id)
    end
    local recent = ExceptionRequests:select("where exception_type_id = ? order by created_at desc limit 5", et.id)
    local group = format_group(et)
    group.recent_exceptions = as_array((function()
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #recent do
        local r = recent[_index_0]
        _accum_0[_len_0] = format_exception(r)
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)())
    return group
  end)
  self:add_tool({
    name = "create_exception",
    description = "Create an exception. It will be auto-grouped by normalized message.",
    inputShape = types.shape({
      message = types.trimmed_text:describe("error message"),
      trace = types.trimmed_text:describe("stack trace"):is_optional(),
      path = types.trimmed_text:describe("request path"):is_optional(),
      method = types.trimmed_text:describe("HTTP method"):is_optional(),
      ip = types.trimmed_text:describe("IP address"):is_optional(),
      data = types.table:describe("additional data"):is_optional()
    })
  }, function(self, params)
    local ereq, new_group = ExceptionRequests:create({
      msg = params.message,
      trace = params.trace,
      path = params.path,
      method = params.method,
      ip = params.ip,
      data = params.data or { }
    })
    local etype = ExceptionTypes:find(ereq.exception_type.id)
    return {
      exception_group = format_group(etype),
      exception = format_exception(ereq),
      new_group = new_group
    }
  end)
  self:add_tool({
    name = "update_exception_group",
    description = "Update the status of an exception group.",
    inputShape = types.shape({
      group_id = types.db_id:describe("exception group ID"),
      status = types.db_enum(ExceptionTypes.statuses):describe("new status")
    })
  }, function(self, params)
    local et = ExceptionTypes:find(params.group_id)
    if not (et) then
      return nil, "Exception group not found: " .. tostring(params.group_id)
    end
    et:update({
      status = params.status
    })
    return format_group(et)
  end)
  self:add_tool({
    name = "delete_exception_group",
    description = "Delete an exception group. Use exceptions_only to keep the group but clear its exceptions.",
    inputShape = types.shape({
      group_id = types.db_id:describe("exception group ID"),
      exceptions_only = types.boolean:describe("only delete exceptions, keep the group"):is_optional()
    })
  }, function(self, params)
    local et = ExceptionTypes:find(params.group_id)
    if not (et) then
      return nil, "Exception group not found: " .. tostring(params.group_id)
    end
    if params.exceptions_only then
      db.delete("exception_requests", {
        exception_type_id = et.id
      })
      et:update({
        count = 0
      })
      return "Deleted all exceptions for group #" .. tostring(et.id) .. ", count reset to 0."
    else
      et:delete()
      return "Deleted exception group #" .. tostring(et.id) .. " and all associated exceptions."
    end
  end)
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionsMcpServer = _class_0
  return _class_0
end
