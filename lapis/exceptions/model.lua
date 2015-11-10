local Model
Model = require("lapis.db.model").Model
return {
  Model = Model:scoped_model("", "lapis.exceptions.models")
}
