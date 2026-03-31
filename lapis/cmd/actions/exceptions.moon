
colors = require "ansicolors"

db = require "lapis.db"
import to_json from require "lapis.util"
import ExceptionRequests, ExceptionTypes from require "lapis.exceptions.models"
import preload from require "lapis.db.model"

types = require "lapis.validate.types"

truncate = (str, len=80) ->
  return "" unless str
  str = str\gsub "\n", " "
  result = types.truncated_text(len)\transform str
  if result and result != str
    result .. "..."
  else
    result or str

format_status = (status_int) ->
  name = ExceptionTypes.statuses\to_name status_int
  switch name
    when "default"
      colors "%{green}#{name}%{reset}"
    when "resolved"
      colors "%{yellow}#{name}%{reset}"
    when "ignored"
      colors "%{dim}#{name}%{reset}"
    else
      name

import string_length from require "lapis.util.utf8"

strip_ansi = (str) ->
  str\gsub "\027%[[%d;]*m", ""

pad_right = (str, width) ->
  visible_len = string_length strip_ansi str
  str .. (" ")\rep math.max(0, width - visible_len)

print_table = (headers, rows, widths) ->
  -- header
  parts = for i, h in ipairs headers
    pad_right h, widths[i]
  print table.concat parts, " | "

  -- separator
  sep_parts = for i in ipairs headers
    ("-")\rep widths[i]
  print table.concat sep_parts, "-+-"

  -- rows
  for row in *rows
    parts = for i in ipairs headers
      pad_right tostring(row[i] or ""), widths[i]
    print table.concat parts, " | "

print_page_info = (page, count) ->
  if count > 0
    print!
    print "Page #{page} (#{count} results)"
    if count >= 50
      print "Use --page #{page + 1} for more"

handle_list = (args) ->
  clauses = {}

  if args.ids and #args.ids > 0
    table.insert clauses, {"id in ?", db.list args.ids}

  if args.status
    table.insert clauses, status: ExceptionTypes.statuses\for_db args.status

  if args.search
    table.insert clauses, {"label @@ plainto_tsquery(?)", args.search}

  if args.search_path
    table.insert clauses, {
      "exists (select 1 from exception_requests where exception_requests.exception_type_id = exception_types.id and path like ?)"
      "%" .. args.search_path .. "%"
    }

  if args.since
    table.insert clauses, {"updated_at >= now() - ?::interval", args.since}

  clause = db.clause clauses, prefix: "where", allow_empty: true

  order = switch args.sort
    when "oldest"
      "ORDER BY updated_at ASC"
    when "count"
      "ORDER BY count DESC"
    when "id"
      "ORDER BY id ASC"
    else
      "ORDER BY updated_at DESC"

  per_page = args.limit or 50
  pager = ExceptionTypes\paginated "? #{order}", clause, {
    :per_page
  }

  page = args.page or 1
  exception_types = pager\get_page page

  if args.json
    print to_json exception_types
    return

  if #exception_types == 0
    print "No exception types found."
    return

  print_table(
    {"ID", "Count", "Status", "Updated", "Label"}
    [{t.id, t.count, format_status(t.status), t.updated_at, truncate(t.label, 60)} for t in *exception_types]
    {6, 7, 10, 20, 60}
  )

  print_page_info page, #exception_types

handle_requests = (args) ->
  per_page = args.limit or 30
  page = args.page or 1

  pager = if args.exception_type_id
    ExceptionRequests\paginated [[
      where exception_type_id = ? order by created_at desc
    ]], args.exception_type_id, {
      :per_page
      prepare_results: (ereqs) ->
        preload ereqs, "exception_type"
        ereqs
    }
  else
    ExceptionRequests\paginated [[
      order by created_at desc
    ]], {
      :per_page
      prepare_results: (ereqs) ->
        preload ereqs, "exception_type"
        ereqs
    }

  requests = pager\get_page page

  if args.json
    print to_json requests
    return

  if #requests == 0
    print "No exception requests found."
    return

  for r in *requests
    print colors "%{bright}Request ##{r.id}%{reset} (#{r.created_at})"
    print "  Type:    ##{r.exception_type_id}"
    print "  Method:  #{r.method or ''}"
    print "  Path:    #{r.path or ''}"
    print "  IP:      #{r.ip or ''}"
    if r.referer
      print "  Referer: #{r.referer}"
    print "  Message: #{r.msg or ''}"
    if args.show_trace and r.trace
      print "  Trace:"
      for line in r.trace\gmatch "[^\n]+"
        print "    #{line}"
    data = r\get_data!
    if data and next(data)
      print "  Data:    #{to_json data}"
    print!

  print_page_info page, #requests

handle_show = (args) ->
  et = ExceptionTypes\find args.exception_type_id
  unless et
    io.stderr\write "Exception type not found: #{args.exception_type_id}\n"
    return

  if args.json
    print to_json et
    return

  print colors "%{bright}Exception Type ##{et.id}%{reset}"
  print "  Status:  #{format_status et.status}"
  print "  Count:   #{et.count}"
  print "  Created: #{et.created_at}"
  print "  Updated: #{et.updated_at}"
  print "  Label:   #{et.label}"
  print!

  -- show recent requests
  recent = ExceptionRequests\select "where exception_type_id = ? order by created_at desc limit 5", et.id
  if #recent > 0
    print colors "%{bright}Recent Requests:%{reset}"
    for r in *recent
      print "  ##{r.id} [#{r.method or '?'}] #{r.path or '?'} (#{r.created_at}) - #{truncate r.msg, 60}"

handle_create = (args) ->
  data = if args.data
    import from_json from require "lapis.util"
    from_json args.data
  else
    {}

  ereq, new_type = ExceptionRequests\create {
    msg: args.message
    trace: args.trace
    path: args.path
    method: args.method
    ip: args.ip
    data: data
  }
  etype = ExceptionTypes\find ereq.exception_type.id

  if args.json
    print to_json {exception_type: etype, exception_request: ereq}
    return

  if new_type
    print colors "%{green}Created new exception type ##{etype.id}%{reset}"
  else
    print colors "%{yellow}Added to existing exception type ##{etype.id} (count: #{etype.count})%{reset}"

  print "  Request ID: #{ereq.id}"
  print "  Label: #{truncate etype.label, 80}"

handle_update = (args) ->
  et = ExceptionTypes\find args.exception_type_id
  unless et
    io.stderr\write "Exception type not found: #{args.exception_type_id}\n"
    return

  unless args.status
    io.stderr\write "Nothing to update. Use --status to set a new status.\n"
    return

  et\update status: ExceptionTypes.statuses\for_db args.status

  if args.json
    print to_json et
    return

  print "Updated exception type ##{et.id} status to #{format_status et.status}"

handle_delete = (args) ->
  et = ExceptionTypes\find args.exception_type_id
  unless et
    io.stderr\write "Exception type not found: #{args.exception_type_id}\n"
    return

  unless args.confirm
    io.write "Delete exception type ##{et.id} (#{truncate et.label, 60}) and all its requests? [y/N] "
    io.flush!
    response = io.read "*l"
    return unless response and response\lower! == "y"

  et\delete!

  if args.json
    print to_json {deleted: true, id: et.id}
    return

  print "Deleted exception type ##{et.id} and all associated requests."

{
  argparser: ->
    with require("argparse") "lapis exceptions", "Manage tracked exceptions"
      \command_target "command"
      \require_command false
      \add_help_command!

      with \command "list", "List exceptions with counts"
        \argument("ids", "Exception type IDs to show")\args("*")\convert(tonumber)
        \option("--sort", "Sort order")\choices({"recent", "oldest", "count", "id"})\default("recent")
        \option("--status -s", "Filter by status")\choices({"default", "resolved", "ignored"})
        \option("--search", "Filter labels by search text")
        \option("--search-path", "Filter to exceptions with requests matching path")
        \option("--since", "Show exceptions updated within this interval (e.g. '24 hours', '7 days')")
        \option("--page -p", "Page number")\default("1")\convert(tonumber)
        \option("--limit", "Results per page")\default("50")\convert(tonumber)
        \flag("--json", "Output as JSON")

      with \command "requests", "List exception requests"
        \argument("exception_type_id", "Exception type ID (optional)")\args("?")\convert(tonumber)
        \option("--page -p", "Page number")\default("1")\convert(tonumber)
        \option("--limit", "Results per page")\default("30")\convert(tonumber)
        \flag("--show-trace", "Show full stack traces")
        \flag("--json", "Output as JSON")

      with \command "show", "Show details for an exception type"
        \argument("exception_type_id", "Exception type ID")\convert(tonumber)
        \flag("--json", "Output as JSON")

      with \command "create", "Create a new exception from the CLI"
        \argument "message", "Exception message"
        \option("--trace", "Stack trace text")
        \option("--path", "Request path")
        \option("--method", "HTTP method")
        \option("--ip", "IP address")
        \option("--data", "JSON data string")
        \flag("--json", "Output as JSON")

      with \command "update", "Update an exception type"
        \argument("exception_type_id", "Exception type ID")\convert(tonumber)
        \option("--status -s", "Set status")\choices({"default", "resolved", "ignored"})
        \flag("--json", "Output as JSON")

      with \command "delete", "Delete an exception type and all its requests"
        \argument("exception_type_id", "Exception type ID")\convert(tonumber)
        \flag("--confirm", "Skip confirmation prompt")
        \flag("--json", "Output as JSON")

  (args, lapis_args) =>
    switch args.command
      when "list", nil then handle_list args
      when "requests" then handle_requests args
      when "show" then handle_show args
      when "create" then handle_create args
      when "update" then handle_update args
      when "delete" then handle_delete args
      else
        error "Unknown command: #{args.command}"
}
