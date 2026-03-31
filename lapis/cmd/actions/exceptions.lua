local colors = require("ansicolors")
local db = require("lapis.db")
local to_json
to_json = require("lapis.util").to_json
local ExceptionRequests, ExceptionTypes
do
  local _obj_0 = require("lapis.exceptions.models")
  ExceptionRequests, ExceptionTypes = _obj_0.ExceptionRequests, _obj_0.ExceptionTypes
end
local preload
preload = require("lapis.db.model").preload
local types = require("lapis.validate.types")
local truncate
truncate = function(str, len)
  if len == nil then
    len = 80
  end
  if not (str) then
    return ""
  end
  str = str:gsub("\n", " ")
  local result = types.truncated_text(len):transform(str)
  if result and result ~= str then
    return result .. "..."
  else
    return result or str
  end
end
local format_status
format_status = function(status_int)
  local name = ExceptionTypes.statuses:to_name(status_int)
  local _exp_0 = name
  if "default" == _exp_0 then
    return colors("%{green}" .. tostring(name) .. "%{reset}")
  elseif "resolved" == _exp_0 then
    return colors("%{yellow}" .. tostring(name) .. "%{reset}")
  elseif "ignored" == _exp_0 then
    return colors("%{dim}" .. tostring(name) .. "%{reset}")
  else
    return name
  end
end
local string_length
string_length = require("lapis.util.utf8").string_length
local strip_ansi
strip_ansi = function(str)
  return str:gsub("\027%[[%d;]*m", "")
end
local pad_right
pad_right = function(str, width)
  local visible_len = string_length(strip_ansi(str))
  return str .. (" "):rep(math.max(0, width - visible_len))
end
local print_table
print_table = function(headers, rows, widths)
  local parts
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i, h in ipairs(headers) do
      _accum_0[_len_0] = pad_right(h, widths[i])
      _len_0 = _len_0 + 1
    end
    parts = _accum_0
  end
  print(table.concat(parts, " | "))
  local sep_parts
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i in ipairs(headers) do
      _accum_0[_len_0] = ("-"):rep(widths[i])
      _len_0 = _len_0 + 1
    end
    sep_parts = _accum_0
  end
  print(table.concat(sep_parts, "-+-"))
  for _index_0 = 1, #rows do
    local row = rows[_index_0]
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i in ipairs(headers) do
        _accum_0[_len_0] = pad_right(tostring(row[i] or ""), widths[i])
        _len_0 = _len_0 + 1
      end
      parts = _accum_0
    end
    print(table.concat(parts, " | "))
  end
end
local print_page_info
print_page_info = function(page, count)
  if count > 0 then
    print()
    print("Page " .. tostring(page) .. " (" .. tostring(count) .. " results)")
    if count >= 50 then
      return print("Use --page " .. tostring(page + 1) .. " for more")
    end
  end
end
local handle_list
handle_list = function(args)
  local clause = db.clause({
    id = (function()
      if args.ids and #args.ids > 0 then
        return db.list(args.ids)
      end
    end)(),
    status = args.status and ExceptionTypes.statuses:for_db(args.status),
    (function()
      if args.search then
        return {
          "label @@ plainto_tsquery(?)",
          args.search
        }
      end
    end)(),
    (function()
      if args.search_path then
        return {
          "exists (select 1 from exception_requests where exception_requests.exception_type_id = exception_types.id and path like ?)",
          "%" .. args.search_path .. "%"
        }
      end
    end)(),
    (function()
      if args.since then
        return {
          "updated_at >= now() - ?::interval",
          args.since
        }
      end
    end)()
  }, {
    prefix = "WHERE",
    allow_empty = true
  })
  local order
  local _exp_0 = args.sort
  if "oldest" == _exp_0 then
    order = "ORDER BY updated_at ASC"
  elseif "count" == _exp_0 then
    order = "ORDER BY count DESC"
  elseif "id" == _exp_0 then
    order = "ORDER BY id ASC"
  else
    order = "ORDER BY updated_at DESC"
  end
  local per_page = args.limit or 50
  local pager = ExceptionTypes:paginated("? " .. tostring(order), clause, {
    per_page = per_page
  })
  local page = args.page or 1
  local exception_types = pager:get_page(page)
  if args.json then
    print(to_json(exception_types))
    return 
  end
  if #exception_types == 0 then
    print("No exception types found.")
    return 
  end
  if args.full then
    for _index_0 = 1, #exception_types do
      local t = exception_types[_index_0]
      print(colors("%{bright}Exception Type #" .. tostring(t.id) .. "%{reset}"))
      print("  Status:  " .. tostring(format_status(t.status)))
      print("  Count:   " .. tostring(t.count))
      print("  Updated: " .. tostring(t.updated_at))
      print("  Label:   " .. tostring(t.label))
      print()
    end
  else
    print_table({
      "ID",
      "Count",
      "Status",
      "Updated",
      "Label"
    }, (function()
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #exception_types do
        local t = exception_types[_index_0]
        _accum_0[_len_0] = {
          t.id,
          t.count,
          format_status(t.status),
          t.updated_at,
          truncate(t.label, 60)
        }
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), {
      6,
      7,
      10,
      20,
      60
    })
  end
  return print_page_info(page, #exception_types)
end
local handle_requests
handle_requests = function(args)
  local per_page = args.limit or 30
  local page = args.page or 1
  local pager
  if args.exception_type_id then
    pager = ExceptionRequests:paginated([[      where exception_type_id = ? order by created_at desc
    ]], args.exception_type_id, {
      per_page = per_page,
      prepare_results = function(ereqs)
        preload(ereqs, "exception_type")
        return ereqs
      end
    })
  else
    pager = ExceptionRequests:paginated([[      order by created_at desc
    ]], {
      per_page = per_page,
      prepare_results = function(ereqs)
        preload(ereqs, "exception_type")
        return ereqs
      end
    })
  end
  local requests = pager:get_page(page)
  if args.json then
    print(to_json(requests))
    return 
  end
  if #requests == 0 then
    print("No exception requests found.")
    return 
  end
  for _index_0 = 1, #requests do
    local r = requests[_index_0]
    print(colors("%{bright}Request #" .. tostring(r.id) .. "%{reset} (" .. tostring(r.created_at) .. ")"))
    print("  Type:    #" .. tostring(r.exception_type_id))
    print("  Method:  " .. tostring(r.method or ''))
    print("  Path:    " .. tostring(r.path or ''))
    print("  IP:      " .. tostring(r.ip or ''))
    if r.referer then
      print("  Referer: " .. tostring(r.referer))
    end
    print("  Message: " .. tostring(r.msg or ''))
    if args.show_trace and r.trace then
      print("  Trace:")
      for line in r.trace:gmatch("[^\n]+") do
        print("    " .. tostring(line))
      end
    end
    local data = r:get_data()
    if data and next(data) then
      print("  Data:    " .. tostring(to_json(data)))
    end
    print()
  end
  return print_page_info(page, #requests)
end
local handle_show
handle_show = function(args)
  local et = ExceptionTypes:find(args.exception_type_id)
  if not (et) then
    io.stderr:write("Exception type not found: " .. tostring(args.exception_type_id) .. "\n")
    return 
  end
  if args.json then
    print(to_json(et))
    return 
  end
  print(colors("%{bright}Exception Type #" .. tostring(et.id) .. "%{reset}"))
  print("  Status:  " .. tostring(format_status(et.status)))
  print("  Count:   " .. tostring(et.count))
  print("  Created: " .. tostring(et.created_at))
  print("  Updated: " .. tostring(et.updated_at))
  print("  Label:   " .. tostring(et.label))
  print()
  local recent = ExceptionRequests:select("where exception_type_id = ? order by created_at desc limit 5", et.id)
  if #recent > 0 then
    print(colors("%{bright}Recent Requests:%{reset}"))
    for _index_0 = 1, #recent do
      local r = recent[_index_0]
      print("  #" .. tostring(r.id) .. " [" .. tostring(r.method or '?') .. "] " .. tostring(r.path or '?') .. " (" .. tostring(r.created_at) .. ") - " .. tostring(truncate(r.msg, 60)))
    end
  end
end
local handle_create
handle_create = function(args)
  local data
  if args.data then
    local from_json
    from_json = require("lapis.util").from_json
    data = from_json(args.data)
  else
    data = { }
  end
  local ereq, new_type = ExceptionRequests:create({
    msg = args.message,
    trace = args.trace,
    path = args.path,
    method = args.method,
    ip = args.ip,
    data = data
  })
  local etype = ExceptionTypes:find(ereq.exception_type.id)
  if args.json then
    print(to_json({
      exception_type = etype,
      exception_request = ereq
    }))
    return 
  end
  if new_type then
    print(colors("%{green}Created new exception type #" .. tostring(etype.id) .. "%{reset}"))
  else
    print(colors("%{yellow}Added to existing exception type #" .. tostring(etype.id) .. " (count: " .. tostring(etype.count) .. ")%{reset}"))
  end
  print("  Request ID: " .. tostring(ereq.id))
  return print("  Label: " .. tostring(truncate(etype.label, 80)))
end
local handle_update
handle_update = function(args)
  if not (args.status) then
    io.stderr:write("Nothing to update. Use --status to set a new status.\n")
    return 
  end
  local _list_0 = args.exception_type_ids
  for _index_0 = 1, #_list_0 do
    local _continue_0 = false
    repeat
      local id = _list_0[_index_0]
      local et = ExceptionTypes:find(id)
      if not (et) then
        io.stderr:write("Exception type not found: " .. tostring(id) .. "\n")
        _continue_0 = true
        break
      end
      et:update({
        status = ExceptionTypes.statuses:for_db(args.status)
      })
      print("Updated exception type #" .. tostring(et.id) .. " status to " .. tostring(format_status(et.status)))
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
local handle_delete
handle_delete = function(args)
  local _list_0 = args.exception_type_ids
  for _index_0 = 1, #_list_0 do
    local _continue_0 = false
    repeat
      local id = _list_0[_index_0]
      local et = ExceptionTypes:find(id)
      if not (et) then
        io.stderr:write("Exception type not found: " .. tostring(id) .. "\n")
        _continue_0 = true
        break
      end
      if args.requests_only then
        if not (args.confirm) then
          io.write("Delete all requests for exception type #" .. tostring(et.id) .. " (" .. tostring(truncate(et.label, 60)) .. ")? [y/N] ")
          io.flush()
          local response = io.read("*l")
          if not (response and response:lower() == "y") then
            _continue_0 = true
            break
          end
        end
        db.delete("exception_requests", {
          exception_type_id = et.id
        })
        et:update({
          count = 0
        })
        print("Deleted all requests for exception type #" .. tostring(et.id) .. ", count reset to 0.")
      else
        if not (args.confirm) then
          io.write("Delete exception type #" .. tostring(et.id) .. " (" .. tostring(truncate(et.label, 60)) .. ") and all its requests? [y/N] ")
          io.flush()
          local response = io.read("*l")
          if not (response and response:lower() == "y") then
            _continue_0 = true
            break
          end
        end
        et:delete()
        print("Deleted exception type #" .. tostring(et.id) .. " and all associated requests.")
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
return {
  argparser = function()
    do
      local _with_0 = require("argparse")("lapis exceptions", "Manage tracked exceptions")
      _with_0:command_target("command")
      _with_0:require_command(false)
      _with_0:add_help_command()
      do
        local _with_1 = _with_0:command("list", "List exceptions with counts")
        _with_1:argument("ids", "Exception type IDs to show"):args("*"):convert(tonumber)
        _with_1:option("--sort", "Sort order"):choices({
          "recent",
          "oldest",
          "count",
          "id"
        }):default("recent")
        _with_1:option("--status -s", "Filter by status"):choices({
          "default",
          "resolved",
          "ignored"
        })
        _with_1:option("--search", "Filter labels by search text")
        _with_1:option("--search-path", "Filter to exceptions with requests matching path")
        _with_1:option("--since", "Show exceptions updated within this interval (e.g. '24 hours', '7 days')")
        _with_1:option("--page -p", "Page number"):default("1"):convert(tonumber)
        _with_1:option("--limit", "Results per page"):default("50"):convert(tonumber)
        _with_1:flag("--full", "Show full output without truncation")
        _with_1:flag("--json", "Output as JSON")
      end
      do
        local _with_1 = _with_0:command("requests", "List exception requests")
        _with_1:argument("exception_type_id", "Exception type ID (optional)"):args("?"):convert(tonumber)
        _with_1:option("--page -p", "Page number"):default("1"):convert(tonumber)
        _with_1:option("--limit", "Results per page"):default("30"):convert(tonumber)
        _with_1:flag("--show-trace", "Show full stack traces")
        _with_1:flag("--json", "Output as JSON")
      end
      do
        local _with_1 = _with_0:command("show", "Show details for an exception type")
        _with_1:argument("exception_type_id", "Exception type ID"):convert(tonumber)
        _with_1:flag("--json", "Output as JSON")
      end
      do
        local _with_1 = _with_0:command("create", "Create a new exception from the CLI")
        _with_1:argument("message", "Exception message")
        _with_1:option("--trace", "Stack trace text")
        _with_1:option("--path", "Request path")
        _with_1:option("--method", "HTTP method")
        _with_1:option("--ip", "IP address")
        _with_1:option("--data", "JSON data string")
        _with_1:flag("--json", "Output as JSON")
      end
      do
        local _with_1 = _with_0:command("update", "Update an exception type")
        _with_1:argument("exception_type_ids", "Exception type IDs"):args("+"):convert(tonumber)
        _with_1:option("--status -s", "Set status"):choices({
          "default",
          "resolved",
          "ignored"
        })
      end
      do
        local _with_1 = _with_0:command("delete", "Delete an exception type and all its requests")
        _with_1:argument("exception_type_ids", "Exception type IDs"):args("+"):convert(tonumber)
        _with_1:flag("--requests-only", "Only delete the requests, keep the exception type")
        _with_1:flag("--confirm", "Skip confirmation prompt")
      end
      return _with_0
    end
  end,
  function(self, args, lapis_args)
    local _exp_0 = args.command
    if "list" == _exp_0 or nil == _exp_0 then
      return handle_list(args)
    elseif "requests" == _exp_0 then
      return handle_requests(args)
    elseif "show" == _exp_0 then
      return handle_show(args)
    elseif "create" == _exp_0 then
      return handle_create(args)
    elseif "update" == _exp_0 then
      return handle_update(args)
    elseif "delete" == _exp_0 then
      return handle_delete(args)
    else
      return error("Unknown command: " .. tostring(args.command))
    end
  end
}
