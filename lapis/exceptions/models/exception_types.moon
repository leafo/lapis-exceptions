db = require "lapis.db"
import Model from require "lapis.exceptions.model"
import enum from require "lapis.db.model"

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

  @statuses: enum {
    default: 1
    resolved: 2
    ignored: 3
  }

  @create: (opts={}) =>
    opts.status or= @statuses\for_db "default"
    Model.create @, opts

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

  delete: =>
    import ExceptionRequests from require "lapis.exceptions.models"
    if super!
      db.delete ExceptionRequests\table_name!, {
        exception_type_id: @id
      }
      true
