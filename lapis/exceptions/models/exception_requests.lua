local db = require("lapis.db")
local Model
Model = require("lapis.exceptions.model").Model
local sanitize_text
sanitize_text = require("lapis.exceptions.helpers").sanitize_text
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
      if type(self.data) == "string" then
        local from_json
        from_json = require("lapis.util").from_json
        return from_json(self.data)
      else
        return self.data
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
    local req, msg, trace, extra_data, ip, path, method, referer
    req, msg, trace, extra_data, ip, path, method, referer = opts.req, opts.msg, opts.trace, opts.extra_data, opts.ip, opts.path, opts.method, opts.referer
    assert(msg, "missing exception message")
    local session = require("lapis.session")
    local data = opts.data or { }
    if req then
      path = path or req.req.parsed_url.path
      method = method or req.req.method
      referer = referer or req.req.referer
      ip = ip or req.req.remote_addr
      local s
      if session.flatten_session then
        s = session.flatten_session(req.session)
      else
        s = session.get_session(req)
      end
      data = {
        extra_data = extra_data,
        request_uri = req.req.request_uri,
        params = req.params,
        session = s,
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
      if opts.data then
        for k, v in pairs(opts.data) do
          data[k] = v
        end
      end
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
      path = sanitize_text(path),
      method = sanitize_text(method),
      ip = sanitize_text(ip),
      msg = sanitize_text(msg),
      trace = sanitize_text(trace),
      exception_type_id = etype.id,
      data = db.raw(db.escape_literal(sanitize_text(to_json(data)))),
      referer = referer ~= "" and sanitize_text(referer) or nil
    })
    ereq.exception_type = etype
    local should_notify = etype:should_notify()
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
