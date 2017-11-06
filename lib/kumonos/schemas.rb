require 'pathname'
require 'json-schema'

module Kumonos
  module Schemas
    ROOT = Pathname.new(File.expand_path('../schemas', __dir__))
    CONFIG_SCHEMA_PATH = ROOT.join('kumonos_config.json')

    class << self
      def validate_kumonos_config(hash)
        schema = load_schema(CONFIG_SCHEMA_PATH)
        JSON::Validator.fully_validate(schema, hash)
      end

      private

      def load_schema(path)
        JSON.parse(File.read(path))
      end
    end
  end
end
