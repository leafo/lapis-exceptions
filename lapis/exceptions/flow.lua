local Flow
Flow = require("lapis.flow").Flow
local ExceptionRequests, ExceptionTypes
do
  local _obj_0 = require("lapis.exceptions.models")
  ExceptionRequests, ExceptionTypes = _obj_0.ExceptionRequests, _obj_0.ExceptionTypes
end
local assert_error
assert_error = require("lapis.application").assert_error
local assert_valid, with_params
do
  local _obj_0 = require("lapis.validate")
  assert_valid, with_params = _obj_0.assert_valid, _obj_0.with_params
end
local preload
preload = require("lapis.db.model").preload
local types = require("lapis.validate.types")
local db = require("lapis.db")
local page_number = types.db_id:describe("integer") * types.custom(function(v)
  return v >= 1, "invalid page number"
end)
local ExceptionFlow
do
  local _class_0
  local _parent_0 = Flow
  local _base_0 = {
    expose_assigns = true,
    find_exception_type = with_params({
      {
        "exception_type_id",
        types.db_id
      }
    }, function(self, params)
      self.exception_type = assert_error(ExceptionTypes:find(params.exception_type_id), "invalid exception")
      return self.exception_type
    end),
    exception_types = with_params({
      {
        "page",
        types.empty / 1 + page_number
      },
      {
        "status",
        types.empty + types.db_enum(ExceptionTypes.statuses)
      },
      {
        "search_label",
        types.empty + types.trimmed_text
      }
    }, function(self, params)
      local clause = db.clause({
        status = params.status,
        (function()
          if params.search_label then
            return {
              "label @@ plainto_tsquery(?)",
              params.search_label
            }
          end
        end)()
      }, {
        prefix = "where",
        allow_empty = true
      })
      self.pager = ExceptionTypes:paginated([[? ORDER BY updated_at DESC]], clause, {
        per_page = 50
      })
      self.page = params.page
      self.exception_types = self.pager:get_page(self.page)
    end),
    exception_requests = with_params({
      {
        "page",
        types.empty / 1 + page_number
      },
      {
        "exception_type_id",
        types.db_id
      }
    }, function(self, params)
      local et = self:find_exception_type()
      self.pager = ExceptionRequests:paginated([[      where exception_type_id = ? order by created_at desc
    ]], params.exception_type_id, {
        per_page = 30,
        prepare_results = function(ereqs)
          preload(ereqs, "exception_type")
          return ereqs
        end
      })
      self.page = params.page
      self.exception_requests = self.pager:get_page(self.page)
    end),
    update_exception = with_params({
      {
        "action",
        types.one_of({
          "update_status",
          "delete"
        })
      }
    }, function(self, params)
      local _exp_0 = params.action
      if "update_status" == _exp_0 then
        local et = self:find_exception_type()
        local status
        status = assert_valid(self.params, types.params_shape({
          {
            "status",
            types.db_enum(ExceptionTypes.statuses)
          }
        })).status
        return et:update({
          status = status
        })
      elseif "delete" == _exp_0 then
        local et = self:find_exception_type()
        return et:delete()
      end
    end)
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
