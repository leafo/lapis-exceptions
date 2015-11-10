db = require "lapis.db"
import Model from require "lapis.exceptions.model"

class ExceptionRequests extends Model
  @timestamp: true

  @create: (r, msg, trace, extra_data) =>
    session = require "lapis.session"

    data = {}
    path = ""
    method = ""
    ip = ""
    referer = ""

    if r
      import req from r

      path = req.parsed_url.path
      method = req.cmd_mth
      referer = req.referer
      ip = req.remote_addr

      data = {
        :extra_data
        cmd_url: req.cmd_url
        params: r.params
        session: session.get_session r
        headers: do
          copy = { k,v for k,v in pairs(req.headers) }
          copy.cookie = nil
          copy.referer = nil
          copy
      }

    local should_notify

    import ExceptionTypes from require "lapis.exceptions.models"
    etype, new_type = ExceptionTypes\find_or_create msg

    if etype\should_send_email!
      should_notify = true
      ExceptionEmail = require "lapis.exceptions.email"
      ExceptionEmail\send r, {
        :msg, :trace, :ip, :method, :path, :data
        label: etype.label
      }

    etype\update count: db.raw "count + 1"

    import to_json from require "lapis.util"

    ereq = Model.create @, {
      :path, :method, :ip, :msg, :trace,

      exception_type_id: etype.id
      data: to_json data
      referer: referer != "" and referer or nil
    }

    ereq, etype, new_type, should_notify

