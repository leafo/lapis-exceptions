schema = require "lapis.db.schema"
import create_table, create_index from schema

import
  serial
  varchar
  text
  time
  integer
  foreign_key
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
}

