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
      db.query "ALTER TABLE exception_requests ALTER COLUMN #{col} DROP NOT NULL"

  [1459407609]: =>
    db.query "ALTER TABLE exception_requests ALTER COLUMN data TYPE jsonb USING data::jsonb"

  [1755025174]: =>
    db.query "ALTER TABLE exception_requests ADD CONSTRAINT exception_requests_exception_type_id_fkey FOREIGN KEY (exception_type_id) REFERENCES exception_types(id) ON DELETE CASCADE"

  [1761609600]: =>
    add_column "exception_types", "last_seen_at", time null: true

    db.query [[
      UPDATE exception_types et
      SET last_seen_at = sub.last_at
      FROM (
        SELECT exception_type_id, MAX(created_at) AS last_at
        FROM exception_requests
        GROUP BY exception_type_id
      ) sub
      WHERE et.id = sub.exception_type_id
    ]]

    db.query "UPDATE exception_types SET last_seen_at = created_at WHERE last_seen_at IS NULL"
    db.query "ALTER TABLE exception_types ALTER COLUMN last_seen_at SET NOT NULL"
    create_index "exception_types", "last_seen_at"

}

