require 'pathname'
require 'json-schema'

module Kumonos
  # Schemas
  module Schemas
    ROOT = Pathname.new(File.expand_path('../schemas', __dir__))
    CONFIG_SCHEMA_PATH = ROOT.join('kumonos_config.json')
    SERVIVE_DEFINITION_PATH = ROOT.join('service_definition.json')

    class << self
      def validate_kumonos_config(hash)
        schema = load_schema(CONFIG_SCHEMA_PATH)
        JSON::Validator.fully_validate(schema, hash)
      end

      def validate_service_definition(hash)
        schema = load_schema(SERVIVE_DEFINITION_PATH)
        JSON::Validator.fully_validate(schema, hash)
      end

      private

      def load_schema(path)
        JSON.parse(File.read(path))
      end
    end
  end
end
