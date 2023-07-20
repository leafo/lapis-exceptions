db = require "lapis.db"
import Model from require "lapis.exceptions.model"
import enum from require "lapis.db.model"

import sanitize_text from require "lapis.exceptions.helpers"

import escape_pattern from require "lapis.util"

-- this will turn any numbers or strings into NUMBER and STRING to allow error to be grouped together better
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

    line_no = P":" * num * P": "

    path_fragment = (P("/") + P("./")) * (1 - line_no)^1 * (line_no / ": ")

    -- clean out paths we don't care about
    path_fragment = Cs(path_fragment) / (s) ->
      if s\match escape_pattern "lapis/application.lua"
        return ""

      s


    string = P"'" * (P(1) - P"'")* P"'"

    -- literal text will prevent the number/string normalization from happening
    -- when the actual value is imporant and should be preserved
    literal_text = P("attempt to index global ") * str +
      P("attempt to call method ") * str +
      P("attempt to index field ") * str +
      P("attempt to index local ") * str +
      P("attempt to perform arithmetic on local ") * str +
      P("bad argument #") * num * P(" to ") * str

    grammar = Cs path_fragment^0 * (literal_text + (num / rep"NUMBER") + (str / rep"STRING") + P(1))^0

  (str) ->
    make_grammar! unless grammar
    first = str\match "^[^\n]+"
    grammar\match(first) or first

-- Generated schema dump: (do not edit)
--
-- CREATE TABLE exception_types (
--   id integer NOT NULL,
--   label text NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   count integer DEFAULT 0 NOT NULL,
--   status smallint DEFAULT 1 NOT NULL
-- );
-- ALTER TABLE ONLY exception_types
--   ADD CONSTRAINT exception_types_pkey PRIMARY KEY (id);
-- CREATE INDEX exception_types_label_idx ON exception_types USING btree (label);
--
class ExceptionTypes extends Model
  @timestamp: true

  @normalize_error = (label) => normalize_error label

  @relations: {
    {"exception_requests", has_many: "ExceptionRequests"}
  }

  @statuses: enum {
    default: 1
    resolved: 2
    ignored: 3
  }

  @create: (opts={}) =>
    opts.label = sanitize_text opts.label
    opts.status = @statuses\for_db opts.status or "default"
    super opts

  @find_or_create: (label) =>
    label = @normalize_error label
    label = sanitize_text label
    et = @find(:label)

    if et
      et, false
    else
      et = @create(:label) -- TODO: this can fail
      et.just_created = true
      et, true

  ignored: =>
    @status == @@statuses.ignored

  resolved: =>
    @status == @@statuses.resolved

  -- just created, or one that hasen't happened in 10 minutes
  should_notify: =>
    return true if @just_created
    return false if @ignored!

    if @resolved!
      @update status: @@statuses.default
      return true

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
