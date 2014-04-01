
db = require "lapis.db"
import Model from require "lapis.db.model"

T = -> true

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

normalize_error = do
  grammar = nil
  make_grammar = ->
    import P, R, Cs from require "lpeg"
    make_str = (delim) ->
      d = P delim
      d * (P[[\]] * d + (P(1) - d))^0 * d

    rep = (name) -> -> "[#{name}]"

    num = R("09")^1 * (P"." * R("09")^1)^-1
    str = make_str([[']]) + make_str([["]])

    line_no = P":" * num * P":"

    string = P"'" * (P(1) - P"'")* P"'"

    grammar = Cs (line_no + (num / rep"NUMBER") + (str / rep"STRING") + P(1))^0

  (str) ->
    make_grammar! unless grammar

    first = str\match "^[^\n]+"
    grammar\match(first) or first


class ExceptionTypes extends Model
  @timestamp: true

  @normalize_error = (label) => normalize_error label

  @find_or_create: (label) =>
    label = @normalize_error label
    et = @find(:label)
    unless et
      et = @create(:label)
      et.should_send_email = T
    et

  -- only send email if one hasn't happened recently
  should_send_email: =>
    date = require "date"
    last_occurrence = date.diff(date(true), date(@updated_at))\spanseconds!
    last_occurrence > 60*10

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
      ExceptionEmail\send r, {
        :msg, :trace, :ip, :method, :path, :data
        label: etype.label
      }

    etype\update count: db.raw "count + 1"

    import to_json from require "lapis.util"

    Model.create @, {
      :path, :method, :ip, :msg, :trace,

      exception_type_id: etype.id
      data: to_json data
      referer: referer != "" and referer or nil
    }

{ :ExceptionRequests, :ExceptionTypes, :make_schema, :normalize_error }
