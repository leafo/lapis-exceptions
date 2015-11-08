# Lapis exception tracker

This module makes the error handler in Lapis save the errors to database.
Optionally you can make it email you the exceptions.

## Installing

```bash
$ luarocks install lapis-exceptions
```

Add a new migration to your app to create the required tables:

```moonscript
require("lapis.exceptions.models").make_schema!
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

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))
Email: leafot@gmail.com
Homepage: <http://leafo.net>
License: MIT

