local db = require("lapis.db")
local Model
Model = require("lapis.exceptions.model").Model
local ExceptionRequests
do
  local _class_0
  local _parent_0 = Model
  local _base_0 = {
    send_email = function(self, req)
      local ExceptionEmail = require("lapis.exceptions.email")
      return ExceptionEmail:send(req, {
        exception_request = self
      })
    end,
    get_data = function(self)
      local from_json
      from_json = require("lapis.util").from_json
      return self.data and from_json(self.data)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "ExceptionRequests",
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
  self.timestamp = true
  self.relations = {
    {
      "exception_type",
      belongs_to = "ExceptionTypes"
    }
  }
  self.create = function(self, opts)
    if opts == nil then
      opts = { }
    end
    local req, msg, trace, extra_data
    req, msg, trace, extra_data = opts.req, opts.msg, opts.trace, opts.extra_data
    assert(msg, "missing exception message")
    local session = require("lapis.session")
    local data = { }
    local path, method, ip, referer
    if req then
      path = req.req.parsed_url.path
      method = req.req.cmd_mth
      referer = req.req.referer
      ip = req.req.remote_addr
      data = {
        extra_data = extra_data,
        cmd_url = req.req.cmd_url,
        params = req.params,
        session = session.get_session(req),
        body = ngx and ngx.req.get_body_data(),
        headers = (function()
          local copy
          do
            local _tbl_0 = { }
            for k, v in pairs(req.req.headers) do
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
    local ExceptionTypes
    ExceptionTypes = require("lapis.exceptions.models").ExceptionTypes
    local etype, new_type = ExceptionTypes:find_or_create(msg)
    etype:update({
      count = db.raw("count + 1")
    })
    local to_json
    to_json = require("lapis.util").to_json
    local ereq = _class_0.__parent.create(self, {
      path = path,
      method = method,
      ip = ip,
      msg = msg,
      trace = trace,
      exception_type_id = etype.id,
      data = to_json(data),
      referer = referer ~= "" and referer or nil
    })
    ereq.exception_type = etype
    local should_notify = etype:should_send_email()
    if should_notify then
      ereq:send_email(self)
    end
    return ereq, new_type, should_notify
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  ExceptionRequests = _class_0
  return _class_0
end
