
import Flow from require "lapis.flow"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

import assert_valid from require "lapis.validate"

db = require "lapis.db"

class ExceptionFlow extends Flow
  expose_assigns: true

  find_exception_type: =>
    assert_valid @params, {
      {"exception_type_id", is_integer: true}
    }

    @exception_type = assert_valid ExceptionTypes\find(@params.exception_type_id), "invalid exception"

  exception_types: =>
    assert_valid @params, {
      {"page", is_integer: true, optional: true}
      {"status", one_of: {unpack ExceptionTypes.statuses}}
    }


    clause = {
      status: @params.status and ExceptionTypes.statuses\for_db @params.status
    }

    @pager = ExceptionTypes\paginated "
      #{next(clause) and "where " .. db.encode_clause(clause) or ""}
      order by updated_at desc
    ", per_page: 50

    @page = tonumber(@params.page) or 1
    @exception_types = @pager\get_page @page

  exception_requests: =>
    assert_valid @params, {
      {"page", is_integer: true, optional: true}
    }

    @find_exception_type!

    @pager = ExceptionRequests\paginated [[
      where exception_type_id = ? order by created_at desc
    ]], @params.exception_type_id, {
      per_page: 30
      prepare_results: (ereqs) =>
        for e in *ereqs
          e.exception_type = @exception_type

        ereqs
    }

    @page = tonumber(@params.page) or 1
    @exceptions = @pager\get_page @page

  update_exception: =>
    @find_exception_type!
    assert_valid @params, {
      {"action", one_of: {"update_status"}}
      {"status", one_of: {unpack ExceptionTypes.statuses}}
    }

    switch @params.action
      when "update_status"
        @exception_type\update {
          status: ExceptionTypes.statuses\for_db @opts.status
        }

