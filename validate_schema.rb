require "json-schema"

BASE_URI = "http://stations.trainline.eu/schema"

Dir["schema/*.json"].each do |path|
  schema = JSON::Validator.parse(File.read(path))
  JSON::Validator.add_schema(JSON::Schema.new(schema, BASE_URI))
end

schema = JSON::Validator.schemas["#{BASE_URI}/stations#"].schema
puts JSON::Validator.fully_validate(schema, "stations.json")
