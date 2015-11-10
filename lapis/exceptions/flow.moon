
import Flow from require "lapis.flow"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"

import assert_valid from require "lapis.validate"

class ExceptionFlow extends Flow
  expose_assigns: true

  exception_requests: =>
    assert_valid @params, {
      {"exception_type_id", is_integer: true}
      {"page", is_integer: true, optional: true}
    }

    @exception_type = ExceptionTypes\find @params.exception_type_id

    @pager = ExceptionRequests\paginated [[
      where exception_type_id = ? order by created_at desc
    ]], @params.exception_type_id

    @page = tonumber(@params.page) or 1
    @exceptions = @pager\get_page @page




