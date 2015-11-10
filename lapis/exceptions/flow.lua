local Flow
Flow = require("lapis.flow").Flow
local ExceptionRequests, ExceptionTypes
do
  local _obj_0 = require("lapis.exceptions.models")
  ExceptionRequests, ExceptionTypes = _obj_0.ExceptionRequests, _obj_0.ExceptionTypes
end
local assert_valid
assert_valid = require("lapis.validate").assert_valid
local ExceptionFlow
do
  local _parent_0 = Flow
  local _base_0 = {
    expose_assigns = true,
    exception_requests = function(self)
      assert_valid(self.params, {
        {
          "exception_type_id",
          is_integer = true
        },
        {
          "page",
          is_integer = true,
          optional = true
        }
      })
      self.exception_type = ExceptionTypes:find(self.params.exception_type_id)
      self.pager = ExceptionRequests:paginated([[      where exception_type_id = ? order by created_at desc
    ]], self.params.exception_type_id)
      self.page = tonumber(self.params.page) or 1
      self.exceptions = self.pager:get_page(self.page)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ExceptionFlow",
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionFlow = _class_0
  return _class_0
end
