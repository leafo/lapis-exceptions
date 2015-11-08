local db = require("lapis.db")
local Model
Model = require("lapis.db.model").Model
local T
T = function()
  return true
end
local config = require("lapis.config").get()
local normalize_error
do
  local grammar = nil
  local make_grammar
  make_grammar = function()
    local P, R, Cs
    do
      local _obj_0 = require("lpeg")
      P, R, Cs = _obj_0.P, _obj_0.R, _obj_0.Cs
    end
    local make_str
    make_str = function(delim)
      local d = P(delim)
      return d * (P([[\]]) * d + (P(1) - d)) ^ 0 * d
    end
    local rep
    rep = function(name)
      return function()
        return "[" .. tostring(name) .. "]"
      end
    end
    local num = R("09") ^ 1 * (P(".") * R("09") ^ 1) ^ -1
    local str = make_str([[']]) + make_str([["]])
    local line_no = P(":") * num * P(":")
    local string = P("'") * (P(1) - P("'")) * P("'")
    grammar = Cs((line_no + (num / rep("NUMBER")) + (str / rep("STRING")) + P(1)) ^ 0)
  end
  normalize_error = function(str)
    if not (grammar) then
      make_grammar()
    end
    local first = str:match("^[^\n]+")
    return grammar:match(first) or first
  end
end
local ExceptionTypes
do
  local _parent_0 = Model
  local _base_0 = {
    should_send_email = function(self)
      if self.just_created then
        return true
      end
      local date = require("date")
      local last_occurrence = date.diff(date(true), date(self.updated_at)):spanseconds()
      return last_occurrence > 60 * 10
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
  self.normalize_error = function(self, label)
    return normalize_error(label)
  end
  self.find_or_create = function(self, label)
    label = self:normalize_error(label)
    local et = self:find({
      label = label
    })
    if et then
      return et, false
    else
      et = self:create({
        label = label
      })
      et.just_created = true
      return et, true
    end
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
    local data = { }
    local path = ""
    local method = ""
    local ip = ""
    local referer = ""
    if r then
      local req
      req = r.req
      path = req.parsed_url.path
      method = req.cmd_mth
      referer = req.referer
      ip = req.remote_addr
      data = {
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
    end
    local should_notify
    local etype, new_type = ExceptionTypes:find_or_create(msg)
    if etype:should_send_email() then
      should_notify = true
      local ExceptionEmail = require("lapis.exceptions.email")
      ExceptionEmail:send(r, {
        msg = msg,
        trace = trace,
        ip = ip,
        method = method,
        path = path,
        data = data,
        label = etype.label
      })
    end
    etype:update({
      count = db.raw("count + 1")
    })
    local to_json
    to_json = require("lapis.util").to_json
    local ereq = Model.create(self, {
      path = path,
      method = method,
      ip = ip,
      msg = msg,
      trace = trace,
      exception_type_id = etype.id,
      data = to_json(data),
      referer = referer ~= "" and referer or nil
    })
    return ereq, etype, new_type, should_notify
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionRequests = _class_0
end
return {
  ExceptionRequests = ExceptionRequests,
  ExceptionTypes = ExceptionTypes,
  normalize_error = normalize_error
}
