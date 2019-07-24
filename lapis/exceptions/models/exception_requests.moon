db = require "lapis.db"
import Model from require "lapis.exceptions.model"

import sanitize_text from require "lapis.exceptions.helpers"

class ExceptionRequests extends Model
  @timestamp: true

  @relations: {
    {"exception_type", belongs_to: "ExceptionTypes"}
  }

  @create: (opts={}) =>
    {:req, :msg, :trace, :extra_data} = opts
    assert msg, "missing exception message"

    session = require "lapis.session"

    data = opts.data or {}
    local path, method, ip, referer

    if req
      path = req.req.parsed_url.path
      method = req.req.cmd_mth
      referer = req.req.referer
      ip = req.req.remote_addr

      s = if session.flatten_session
        session.flatten_session req.session
      else
        session.get_session req

      data = {
        :extra_data
        cmd_url: req.req.cmd_url
        params: req.params
        session: s
        body: ngx and ngx.req.get_body_data!
        headers: do
          copy = { k,v for k,v in pairs(req.req.headers) }
          copy.cookie = nil
          copy.referer = nil
          copy
      }

      if opts.data
        for k,v in pairs opts.data
          data[k] = v

    import ExceptionTypes from require "lapis.exceptions.models"

    etype, new_type = ExceptionTypes\find_or_create msg
    etype\update count: db.raw "count + 1"

    import to_json from require "lapis.util"

    ereq = super {
      path: sanitize_text path
      method: sanitize_text method
      ip: sanitize_text ip
      msg: sanitize_text msg
      trace: sanitize_text trace

      exception_type_id: etype.id
      data: db.raw db.escape_literal sanitize_text to_json data
      referer: referer != "" and sanitize_text(referer) or nil
    }

    -- preload the relation
    ereq.exception_type = etype

    should_notify = etype\should_notify!

    if should_notify
      ereq\send_email @

    ereq, new_type, should_notify

  send_email: (req) =>
    ExceptionEmail = require "lapis.exceptions.email"
    ExceptionEmail\send req, {
      exception_request: @
    }

  get_data: =>
    if type(@data) == "string"
      -- legacy path for old schema
      import from_json from require "lapis.util"
      from_json @data
    else
      @data

