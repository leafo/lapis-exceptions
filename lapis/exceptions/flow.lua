local Flow
Flow = require("lapis.flow").Flow
local ExceptionRequests, ExceptionTypes
do
  local _obj_0 = require("lapis.exceptions.models")
  ExceptionRequests, ExceptionTypes = _obj_0.ExceptionRequests, _obj_0.ExceptionTypes
end
local assert_error
assert_error = require("lapis.application").assert_error
local assert_valid
assert_valid = require("lapis.validate").assert_valid
local db = require("lapis.db")
local ExceptionFlow
do
  local _class_0
  local _parent_0 = Flow
  local _base_0 = {
    expose_assigns = true,
    find_exception_type = function(self)
      assert_valid(self.params, {
        {
          "exception_type_id",
          is_integer = true
        }
      })
      self.exception_type = assert_error(ExceptionTypes:find(self.params.exception_type_id), "invalid exception")
    end,
    exception_types = function(self)
      assert_valid(self.params, {
        {
          "page",
          is_integer = true,
          optional = true
        },
        {
          "status",
          one_of = {
            unpack(ExceptionTypes.statuses)
          }
        }
      })
      local clause = {
        status = self.params.status and ExceptionTypes.statuses:for_db(self.params.status)
      }
      self.pager = ExceptionTypes:paginated("\n      " .. tostring(next(clause) and "where " .. db.encode_clause(clause) or "") .. "\n      order by updated_at desc\n    ", {
        per_page = 50
      })
      self.page = tonumber(self.params.page) or 1
      self.exception_types = self.pager:get_page(self.page)
    end,
    exception_requests = function(self)
      assert_valid(self.params, {
        {
          "page",
          is_integer = true,
          optional = true
        }
      })
      self:find_exception_type()
      self.pager = ExceptionRequests:paginated([[      where exception_type_id = ? order by created_at desc
    ]], self.params.exception_type_id, {
        per_page = 30,
        prepare_results = function(ereqs)
          for _index_0 = 1, #ereqs do
            local e = ereqs[_index_0]
            e.exception_type = self.exception_type
          end
          return ereqs
        end
      })
      self.page = tonumber(self.params.page) or 1
      self.exceptions = self.pager:get_page(self.page)
    end,
    update_exception = function(self)
      self:find_exception_type()
      assert_valid(self.params, {
        {
          "action",
          one_of = {
            "update_status"
          }
        },
        {
          "status",
          one_of = {
            unpack(ExceptionTypes.statuses)
          }
        }
      })
      local _exp_0 = self.params.action
      if "update_status" == _exp_0 then
        return self.exception_type:update({
          status = ExceptionTypes.statuses:for_db(self.opts.status)
        })
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ExceptionFlow",
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionFlow = _class_0
  return _class_0
end
