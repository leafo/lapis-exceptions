
import Flow from require "lapis.flow"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

import assert_valid from require "lapis.validate"

class ExceptionFlow extends Flow
  expose_assigns: true

  exception_types: =>
    assert_valid @params, {
      {"page", is_integer: true, optional: true}
    }

    @pager = ExceptionTypes\paginated "order by updated_at desc", per_page: 50

    @page = tonumber(@params.page) or 1
    @exception_types = @pager\get_page @page

  exception_requests: =>
    assert_valid @params, {
      {"exception_type_id", is_integer: true}
      {"page", is_integer: true, optional: true}
    }

    @exception_type = ExceptionTypes\find @params.exception_type_id

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




