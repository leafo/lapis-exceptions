local schema = require("lapis.db.schema")
local create_table, create_index
create_table, create_index = schema.create_table, schema.create_index
local serial, varchar, text, time, integer, foreign_key
do
  local _obj_0 = schema.types
  serial, varchar, text, time, integer, foreign_key = _obj_0.serial, _obj_0.varchar, _obj_0.text, _obj_0.time, _obj_0.integer, _obj_0.foreign_key
end
return {
  [1446940278] = function(self)
    local entity_exists
    entity_exists = require("lapis.db.schema").entity_exists
    if entity_exists("exception_types") then
      return 
    end
    create_table("exception_types", {
      {
        "id",
        serial
      },
      {
        "label",
        text
      },
      {
        "created_at",
        time
      },
      {
        "updated_at",
        time
      },
      {
        "count",
        integer
      },
      "PRIMARY KEY (id)"
    })
    create_index("exception_types", "label")
    create_table("exception_requests", {
      {
        "id",
        serial
      },
      {
        "exception_type_id",
        foreign_key
      },
      {
        "path",
        text
      },
      {
        "method",
        varchar
      },
      {
        "referer",
        text({
          null = true
        })
      },
      {
        "ip",
        varchar
      },
      {
        "data",
        text
      },
      {
        "msg",
        text
      },
      {
        "trace",
        text
      },
      {
        "created_at",
        time
      },
      {
        "updated_at",
        time
      },
      "PRIMARY KEY (id)"
    })
    return create_index("exception_requests", "exception_type_id")
  end
}
