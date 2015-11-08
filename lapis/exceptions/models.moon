
db = require "lapis.db"
import Model from require "lapis.db.model"

T = -> true

config = require("lapis.config").get!

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

    if et
      et, false
    else
      et = @create(:label) -- TODO: this can fail
      et.just_created = true
      et, true

  -- just created, or one that hasen't happened in 10 minutes
  should_send_email: =>
    return true if @just_created
    date = require "date"
    last_occurrence = date.diff(date(true), date(@updated_at))\spanseconds!
    last_occurrence > 60*10

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

{ :ExceptionRequests, :ExceptionTypes, :normalize_error }
