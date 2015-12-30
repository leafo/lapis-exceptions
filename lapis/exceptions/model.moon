import Model from require "lapis.db.model"

Model = Model\scoped_model "", "lapis.exceptions.models"
Model.get_relation_model = (name) =>
  require("lapis.exceptions.models")[name]


{
  :Model
}
