
import Widget from require "lapis.html"

config = require("lapis.config").get!

class ExceptionEmail extends Widget
  @send: (r, ...) =>
    return unless config.admin_email
    import send_email from require "helpers.email"
    send_email config.admin_email, @render r, ...

  @render: (r, params) =>
    i = @(params)
    i\include_helper r
    i\subject!, i\render_to_string!, html: true

  subject: =>
    "[#{config.app_name or "lapis"} exception] #{@label}"

  content: =>
    h2 "There was an exception"
    pre @msg
    pre @trace

    p "The exception happened #{os.date "!%c"}"

    h2 "Request"
    pre ->
      strong "method: "
      text @method

    pre ->
      strong "path: "
      text @path

    pre ->
      strong "ip: "
      text @ip

    moon = require "moon"
    for k,v in pairs @data
      pre ->
        strong "#{k}: "
        text moon.dump v


