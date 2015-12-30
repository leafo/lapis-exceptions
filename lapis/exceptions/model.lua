local Model
Model = require("lapis.db.model").Model
Model = Model:scoped_model("", "lapis.exceptions.models")
Model.get_relation_model = function(self, name)
  return require("lapis.exceptions.models")[name]
end
return {
  Model = Model
}
