# Lapis exception tracker

![test](https://github.com/leafo/lapis-exceptions/workflows/test/badge.svg)

This module makes the error handler in Lapis save the errors to database.
Optionally you can make it email you the exceptions.


<details>
<summary><strong>Are you updating from before 2.0?</strong></summary>

You may need to run migrations. Add a new migration to your app and call
`run_migrations`. It's safe to call it multiple times with no side effects so
you're free to add that migration every time you update.


```lua
  [XXX] = require("lapis.exceptions.schema").run_migrations
```

</details>


## Installing

```bash
$ luarocks install lapis-exceptions
```

Create a new migration that look like this. This will create the necessary
tables for storing errors, and make any updates to the scchema if necessary. If
you are updating the library, you may need to run migrations again. See the
upgrade details in the release notes.

```lua
-- migrations.moon/lua
{
  ...

  [1439944992]: require("lapis.exceptions.schema").run_migrations
}
```

Enable it in your top level app by calling `@enable`. This will wrap your app's
`handle_error` method with a new function that can record errors, and then call
the previous function.

```moon
class App extends lapis.Application
  @enable "exception_tracking"

  -- ...
```

Lastly, add to `track_exceptions true` to each environment you want the
exception tracking to happen, along with any other optional configuration. This
will cause the error handler to stard recording errors into the database.


```moon
-- config.moon
config = require "lapis.config"

config "production", ->
  track_exceptions true

  -- app_name "My app" --> optional, gives title to emails
  -- admin_email "me@example.com" --> optional, sends email to you
  -- ...
```

## Emails

Lapis doesn't have a standardized email sending interface yet, in order for
mail to work you need to provide your own `send_mail` function.

The exception mailer will look for a module called `helpers.email` and it
should contain a function called `send_email` that takes as arguments the
recipient email address, the subject, and the body.

```
-- this should work to be able to send exception emails:
require("helpers.email").send_email "leafo@example.com", "Hello!", "This is an email"
```

You can find an [example send_mail implementation in the MoonRocks
repository](https://github.com/leafo/moonrocks-site/blob/master/helpers/email.moon).

An email will be sent to `config.admin_email` every time a new exception type
is created, or every time an exception type is updated if it's been 10 minutes
since the last update.

## Protected calls

Two functions are provided for running code with error capturing. Any errors
that happen will be captured and written to the exception request table. The
error will not propagate outside the call. It works similar to Lua's `pcall`.


```moonscript
import protected_call from require "lapis.exceptions"

success, ret = protected_call ->
  hello = 3 + "what"

```

If you're running in a Lapis request context, you can pass a request object as
the first argument to record any information about that request:


```moonscript
lapis = require "lapis"
import protected_call from require "lapis.exceptions"

class App extends lapis.Application
  "/": =>
    success, ret = protected_call @, ->
      error "something failed"

    "ok"
```



## CLI

A `lapis exceptions` command is provided for managing exceptions from the
terminal. It must be run from a Lapis project directory with a valid
configuration.

```bash
# List recent exception groups (default command)
$ lapis exceptions

# List with filters
$ lapis exceptions list --status resolved --sort count --since '7 days'

# Search exceptions by message or request path
$ lapis exceptions list --search "timeout" --search-path "/api/"

# Show details for a specific exception group
$ lapis exceptions show 42

# List individual requests for a group
$ lapis exceptions requests 42 --show-trace

# Update status of exception groups
$ lapis exceptions update 42 43 --status ignored

# Delete exception groups
$ lapis exceptions delete 42 43

# Create an exception manually
$ lapis exceptions create "something went wrong" --path "/test" --method POST
```

All list commands support `--json` for machine-readable output, and `--page`
/ `--limit` for pagination.

## MCP Server

An MCP (Model Context Protocol) server is available for integrating exception
management with AI tools like Claude. Start it over stdio with:

```bash
$ lapis mcp lapis.exceptions.mcp_server
```

To add it to your MCP client configuration (e.g. Claude Desktop or Claude
Code):

```json
{
  "mcpServers": {
    "lapis-exceptions": {
      "command": "lapis",
      "args": ["mcp", "lapis.exceptions.mcp_server"],
      "cwd": "/path/to/your/lapis/project"
    }
  }
}
```

The server provides the following tools:

- `list_exception_groups` -- list and filter exception groups
- `list_exceptions` -- list individual exception requests
- `show_exception_group` -- show group details with recent exceptions
- `create_exception` -- create a new exception
- `update_exception_group` -- update group status
- `delete_exception_group` -- delete a group and its exceptions

## Models

Two models are created to hold exception data: `ExceptionTypes` and
`ExceptionRequests`. `ExceptionTypes` holds normalized exception messages.
`ExceptionRequests` holds the original exception message along with data about
the request. It has a foreign key pointing to the exception type it belongs to.


The models can be accessed like so:

```moonscript
import ExceptionTypes, ExceptionRequests from require "lapis.exceptions.models"
```

## Exception grouping

Exceptions are grouped by their exception message in order to reduce the amount
of top level issues created. A normalized exception message is stored in the
`ExceptionTypes` table. Numbers and strings are replaced by generic
identifiers, line numbers are left alone.

For example, the following exception message:

    ./lapis/nginx/postgres.lua:51: header part is incomplete: select id from hello_world where name = 'yeah' and age > 10

Would be normalized to:

    ./lapis/nginx/postgres.lua:51: header part is incomplete: select id from hello_world where name = [STRING] and age > [NUMBER]

Before being stored in the database.

# Changelog

<https://github.com/leafo/lapis-exceptions/releases>

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))
Email: leafot@gmail.com
Homepage: <http://leafo.net>
License: MIT

