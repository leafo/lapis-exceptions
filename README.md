
# Lapis exception tracker

This module makes the error handler in Lapis save the errors to database.
Optionally you can make it email you the exceptions.

Requires `lapis >= 0.0.10`.

## Installing

```bash
$ luarocks install https://raw.github.com/leafo/lapis-exceptions/master/lapis-exceptions-dev-1.rockspec
```

Create the required tables:

```moonscript
require("lapis.exceptions.models").make_schema!
```

Enable it in your config in the appropriate environments:

```moon
-- config.moon
config = require "lapis.config"

config "production", ->
  exception_tracking true

  -- app_name "My app" --> optional, gives title to emails
  -- admin_email "me@example.com" --> optional, sends email to you

-- ...
```

Enable it in your top level app by calling `@enable`:

```moon
class App extends lapis.Application
  @enable "exception_tracking"

  -- ...
```

## Emails

Lapis doesn't have a proper email sending interface yet, in order for mail to
work you need to provide your own `send_mail` function.

The exception mailer will look for a module called `helpers.email` and it
should contain a function called `send_email` that takes as arguments the
recipient email address, the subject, and the body.

```
-- this should work to be able to send exception emails:
require("helpers.email").send_email "leafo@example.com", "Hello!", "This is an email"
```

## Getting the exceptions

There's no admin panel for viewing exceptions inside the web app yet. You'll
have to manually run queries in the database or use the emails.


# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  
License: MIT

