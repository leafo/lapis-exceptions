
db = require "lapis.db"
import Model from require "lapis.db.model"

config = require("lapis.config").get!

make_schema = ->
  schema = require "lapis.db.schema"
  import create_table, create_index from schema

  import
    serial
    varchar
    text
    time
    integer
    foreign_key
    from schema.types

  create_table "exception_types", {
    {"id", serial}
    {"label", text}

    {"created_at", time}
    {"updated_at", time}
    {"count", integer}

    "PRIMARY KEY (id)"
  }

  create_index "exception_types", "label"

  create_table "exception_requests", {
    {"id", serial}
    {"exception_type_id", foreign_key}
    {"path", text}
    {"method", varchar}
    {"referer", text null: true}
    {"ip", varchar}
    {"data", text}

    {"msg", text}
    {"trace", text}

    {"created_at", time}
    {"updated_at", time}

    "PRIMARY KEY (id)"
  }

  create_index "exception_requests", "exception_type_id"

class ExceptionTypes extends Model
  @timestamp: true

  @normalize_label = (label) =>
    label\match "^([^\n]*)"

  @find_or_create: (label) =>
    label = @normalize_label label
    @find(:label) or Model.create(@, :label)

  -- only send email if one hasn't happened recently
  should_send_email: =>
    date = require "date"
    last_occurrence = date.diff(date(true), date(@updated_at))\spanseconds!
    @created_at != @updated_at and last_occurrence > 60*10

    return false if last_occurrence > 60*10 or @created_at == @updated_at

class ExceptionRequests extends Model
  @timestamp: true

  @create: (r, msg, trace, extra_data) =>
    session = require "lapis.session"
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

    etype = ExceptionTypes\find_or_create msg

    if etype\should_send_email!
      ExceptionEmail = require "lapis.exceptions.email"
      ExceptionEmail\send r, etype, :msg, :trace, :ip, :method, :path, :data

    etype\update count: db.raw "count + 1"

    import to_json from require "lapis.util"

    Model.create @, {
      :path, :method, :ip, :msg, :trace,

      exception_type_id: etype.id
      data: to_json data
      referer: referer != "" and referer or nil
    }


{ :ExceptionRequests, :ExceptionTypes, :make_schema }
