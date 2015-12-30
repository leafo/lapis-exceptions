
import Widget from require "lapis.html"

config = require("lapis.config").get!

class ExceptionEmail extends Widget
  @send: (r, ...) =>
    return unless config.admin_email
    import send_email from require "helpers.email"
    send_email config.admin_email, @render r, ...

  @render: (r, params) =>
    i = @(params)
    i\include_helper r if r
    i\subject!, i\render_to_string!, html: true

  @needs: {"exception_request"}

  subject: =>
    etype = @exception_request\get_exception_type!
    "[#{config.app_name or "lapis"} exception] #{etype.label}"

  content: =>
    etype = @exception_request\get_exception_type!

    h2 "There was an exception"
    pre @exception_request.msg
    pre @exception_request.trace

    p "The exception happened #{os.date "!%c"}"

    if @exception_request.method
      h2 "Request"
      pre ->
        strong "method: "
        text @exception_request.method

      pre ->
        strong "path: "
        text @exception_request.path

      pre ->
        strong "ip: "
        text @exception_request.ip

    data = @exception_request\get_data!
    if next data
      moon = require "moon"
      pre ->
        text moon.dump


