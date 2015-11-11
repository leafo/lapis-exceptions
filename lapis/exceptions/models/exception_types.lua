local db = require("lapis.db")
local Model
Model = require("lapis.exceptions.model").Model
local enum
enum = require("lapis.db.model").enum
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
  self.statuses = enum({
    default = 1,
    resolved = 2,
    ignored = 3
  })
  self.create = function(self, opts)
    if opts == nil then
      opts = { }
    end
    opts.status = opts.status or self.statuses:for_db("default")
    return Model.create(self, opts)
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
  return _class_0
end
