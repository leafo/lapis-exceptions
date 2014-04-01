local Widget
do
  local _obj_0 = require("lapis.html")
  Widget = _obj_0.Widget
end
local config = require("lapis.config").get()
local ExceptionEmail
do
  local _parent_0 = Widget
  local _base_0 = {
    subject = function(self)
      return "[" .. tostring(config.app_name or "lapis") .. " exception] " .. tostring(self.label)
    end,
    content = function(self)
      h2("There was an exception")
      pre(self.msg)
      pre(self.trace)
      p("The exception happened " .. tostring(os.date("!%c")))
      h2("Request")
      pre(function()
        strong("method: ")
        return text(self.method)
      end)
      pre(function()
        strong("path: ")
        return text(self.path)
      end)
      pre(function()
        strong("ip: ")
        return text(self.ip)
      end)
      local moon = require("moon")
      for k, v in pairs(self.data) do
        pre(function()
          strong(tostring(k) .. ": ")
          return text(moon.dump(v))
        end)
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
    __name = "ExceptionEmail",
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
  self.send = function(self, r, ...)
    if not (config.admin_email) then
      return 
    end
    local send_email
    do
      local _obj_0 = require("helpers.email")
      send_email = _obj_0.send_email
    end
    return send_email(config.admin_email, self:render(r, ...))
  end
  self.render = function(self, r, params)
    local i = self(params)
    i:include_helper(r)
    return i:subject(), i:render_to_string(), {
      html = true
    }
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionEmail = _class_0
  return _class_0
end
