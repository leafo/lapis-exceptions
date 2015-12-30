db = require "lapis.db"
import Model from require "lapis.exceptions.model"

class ExceptionRequests extends Model
  @timestamp: true

  @relations: {
    {"exception_type", belongs_to: "ExceptionTypes"}
  }

  @create: (opts={}) =>
    {:req, :msg, :trace, :extra_data} = opts
    assert msg, "missing exception message"

    session = require "lapis.session"

    data = {}
    local path, method, ip, referer

    if req
      path = req.req.parsed_url.path
      method = req.req.cmd_mth
      referer = req.req.referer
      ip = req.req.remote_addr

      data = {
        :extra_data
        cmd_url: req.req.cmd_url
        params: req.params
        session: session.get_session req
        body: ngx and ngx.req.get_body_data!
        headers: do
          copy = { k,v for k,v in pairs(req.req.headers) }
          copy.cookie = nil
          copy.referer = nil
          copy
      }

    local should_notify

    import ExceptionTypes from require "lapis.exceptions.models"
    etype, new_type = ExceptionTypes\find_or_create msg

    should_notify = etype\should_send_email!

    if should_notify and req
      ExceptionEmail = require "lapis.exceptions.email"
      ExceptionEmail\send req, {
        :msg, :trace, :ip, :method, :path, :data
        label: etype.label
      }

    etype\update count: db.raw "count + 1"

    import to_json from require "lapis.util"

    ereq = super {
      :path, :method, :ip, :msg, :trace,
      exception_type_id: etype.id
      data: to_json data
      referer: referer != "" and referer or nil
    }

    ereq, etype, new_type, should_notify

  get_data: =>
    import from_json from require "lapis.util"
    @data and from_json @data

