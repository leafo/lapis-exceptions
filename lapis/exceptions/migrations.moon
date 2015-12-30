schema = require "lapis.db.schema"
db = require "lapis.db"

import create_table, create_index, add_column from schema

import
  serial
  varchar
  text
  time
  integer
  foreign_key
  enum
  from schema.types

{
  [1446940278]: =>
    import entity_exists from require "lapis.db.schema"

    -- if the table exists then skip since it was created before migrations
    return if entity_exists "exception_types"

    create_table "exception_types", {
      {"id", serial}
      {"label", text}

      {"created_at", time}
      {"updated_at", time}
      {"count", integer}

      "PRIMARY KEY (id)"
    }

    create_index "exception_types", "label"

    create_table "exception_requests", {
      {"id", serial}
      {"exception_type_id", foreign_key}
      {"path", text}
      {"method", varchar}
      {"referer", text null: true}
      {"ip", varchar}
      {"data", text}

      {"msg", text}
      {"trace", text}

      {"created_at", time}
      {"updated_at", time}

      "PRIMARY KEY (id)"
    }

    create_index "exception_requests", "exception_type_id"

  [1446941278]: =>
    add_column "exception_types", "status", enum default: 1

  [1451464107]: =>
    for col in *{
      "path"
      "method"
      "ip"
      "data"
      "trace"
    }
      db.query "alter table exception_requests alter column #{col} drop not null"

}

