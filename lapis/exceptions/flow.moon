
import Flow from require "lapis.flow"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

import assert_error from require "lapis.application"
import assert_valid, with_params from require "lapis.validate"

import preload from require "lapis.db.model"

types = require "lapis.validate.types"

db = require "lapis.db"

page_number = types.db_id\describe("integer") * types.custom (v) -> v >= 1, "invalid page number"

class ExceptionFlow extends Flow
  expose_assigns: true

  find_exception_type: with_params {
    {"exception_type_id", types.db_id}
  }, (params) =>
    @exception_type = assert_error ExceptionTypes\find(params.exception_type_id), "invalid exception"
    @exception_type

  exception_types: with_params {
    {"page", types.empty / 1 + page_number}
    {"status", types.empty + types.db_enum ExceptionTypes.statuses}
    {"search_label", types.empty + types.trimmed_text}
  }, (params) =>
    clause = db.clause {
      status: params.status
      if params.search_label
        {"label @@ plainto_tsquery(?)", params.search_label}

    }, prefix: "where", allow_empty: true

    @pager = ExceptionTypes\paginated [[? ORDER BY updated_at DESC]], clause, {
      per_page: 50
    }

    @page = params.page
    @exception_types = @pager\get_page @page

  exception_requests: with_params {
    {"page", types.empty / 1 + page_number}
    {"exception_type_id", types.db_id}
  }, (params) =>
    et = @find_exception_type!

    @pager = ExceptionRequests\paginated [[
      where exception_type_id = ? order by created_at desc
    ]], params.exception_type_id, {
      per_page: 30
      prepare_results: (ereqs) ->
        preload ereqs, "exception_type"
        ereqs
    }

    @page = params.page
    @exception_requests = @pager\get_page @page

  update_exception: with_params {
    {"action", types.one_of {"update_status", "delete"}}
  }, (params) =>
    switch params.action
      when "update_status"
        et = @find_exception_type!

        {:status} = assert_valid @params, types.params_shape {
          {"status", types.db_enum ExceptionTypes.statuses}
        }

        et\update { :status }
      when "delete"
        et = @find_exception_type!
        et\delete!

