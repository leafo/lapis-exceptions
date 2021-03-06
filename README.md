# Lapis exception tracker

![test](https://github.com/leafo/lapis-exceptions/workflows/test/badge.svg)

This module makes the error handler in Lapis save the errors to database.
Optionally you can make it email you the exceptions.


## Updated to 2.0 or beyond?

You may need to run migrations. Add a new migration to your app and call
`run_migrations`. It's safe to call it multiple times with no side effects so
you're free to add that migration every time you update.


```lua
  [XXX]: require("lapis.exceptions.schema").run_migrations
```

## Installing

```bash
$ luarocks install lapis-exceptions
```

Create a new migration that look like this:

```lua
-- migrations.moon/lua
{
  ...

  [1439944992]: require("lapis.exceptions.schema").run_migrations
}
```

Enable it in your top level app by calling `@enable`:

```moon
class App extends lapis.Application
  @enable "exception_tracking"

  -- ...
```

Lastly, add to `track_exceptions true` to each environment you want the
exception tracking to happen, along with any other optional configuration:

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



## Getting the exceptions

There's no admin panel for viewing exceptions inside the web app yet. You'll
have to manually run queries in the database or use the emails.

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

### Jan 25 2021 `2.0`

* Support for latest vesrions of Lapis
* Data fields now stored as json
* Add `protected_call` function
* Fields `ip`, `path`, `method`, `referer` can be overriden when creating exception
* Sanitize UTF8 input strings to ensure recording exceptions does not trigger an error
* A bunch of minor updates, no interface changes

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))
Email: leafot@gmail.com
Homepage: <http://leafo.net>
License: MIT

