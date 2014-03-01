local db = require("lapis.db")
local Model
do
  local _obj_0 = require("lapis.db.model")
  Model = _obj_0.Model
end
local config = require("lapis.config").get()
local make_schema
make_schema = function()
  local schema = require("lapis.db.schema")
  local create_table, create_index
  create_table, create_index = schema.create_table, schema.create_index
  local serial, varchar, text, time, integer, foreign_key
  do
    local _obj_0 = schema.types
    serial, varchar, text, time, integer, foreign_key = _obj_0.serial, _obj_0.varchar, _obj_0.text, _obj_0.time, _obj_0.integer, _obj_0.foreign_key
  end
  create_table("exception_types", {
    {
      "id",
      serial
    },
    {
      "label",
      text
    },
    {
      "created_at",
      time
    },
    {
      "updated_at",
      time
    },
    {
      "count",
      integer
    },
    "PRIMARY KEY (id)"
  })
  create_index("exception_types", "label")
  create_table("exception_requests", {
    {
      "id",
      serial
    },
    {
      "exception_type_id",
      foreign_key
    },
    {
      "path",
      text
    },
    {
      "method",
      varchar
    },
    {
      "referer",
      text({
        null = true
      })
    },
    {
      "ip",
      varchar
    },
    {
      "data",
      text
    },
    {
      "msg",
      text
    },
    {
      "trace",
      text
    },
    {
      "created_at",
      time
    },
    {
      "updated_at",
      time
    },
    "PRIMARY KEY (id)"
  })
  return create_index("exception_requests", "exception_type_id")
end
local ExceptionTypes
do
  local _parent_0 = Model
  local _base_0 = {
    should_send_email = function(self)
      local date = require("date")
      local last_occurrence = date.diff(date(true), date(self.updated_at)):spanseconds()
      local _ = self.created_at ~= self.updated_at and last_occurrence > 60 * 10
      if last_occurrence > 60 * 10 or self.created_at == self.updated_at then
        return false
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ExceptionTypes",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
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
  self.timestamp = true
  self.normalize_label = function(self, label)
    return label:match("^([^\n]*)")
  end
  self.find_or_create = function(self, label)
    label = self:normalize_label(label)
    return self:find({
      label = label
    }) or Model.create(self, {
      label = label
    })
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionTypes = _class_0
end
local ExceptionRequests
do
  local _parent_0 = Model
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ExceptionRequests",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
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
  self.timestamp = true
  self.create = function(self, r, msg, trace, extra_data)
    local session = require("lapis.session")
    local req
    req = r.req
    local path = req.parsed_url.path
    local method = req.cmd_mth
    local referer = req.referer
    local ip = req.remote_addr
    local data = {
      extra_data = extra_data,
      cmd_url = req.cmd_url,
      params = r.params,
      session = session.get_session(r),
      headers = (function()
        local copy
        do
          local _tbl_0 = { }
          for k, v in pairs(req.headers) do
            _tbl_0[k] = v
          end
          copy = _tbl_0
        end
        copy.cookie = nil
        copy.referer = nil
        return copy
      end)()
    }
    local etype = ExceptionTypes:find_or_create(msg)
    if etype:should_send_email() then
      local ExceptionEmail = require("lapis.exceptions.email")
      ExceptionEmail:send(r, etype, {
        msg = msg,
        trace = trace,
        ip = ip,
        method = method,
        path = path,
        data = data
      })
    end
    etype:update({
      count = db.raw("count + 1")
    })
    local to_json
    do
      local _obj_0 = require("lapis.util")
      to_json = _obj_0.to_json
    end
    return Model.create(self, {
      path = path,
      method = method,
      ip = ip,
      msg = msg,
      trace = trace,
      exception_type_id = etype.id,
      data = to_json(data),
      referer = referer ~= "" and referer or nil
    })
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionRequests = _class_0
end
return {
  ExceptionRequests = ExceptionRequests,
  ExceptionTypes = ExceptionTypes,
  make_schema = make_schema
}
