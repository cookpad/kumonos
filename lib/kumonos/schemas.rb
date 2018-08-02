# frozen_string_literal: true

require 'pathname'
require 'json-schema'

module Kumonos
  # Schemas
  module Schemas
    ROOT = Pathname.new(File.expand_path('../schemas', __dir__))
    ENVOY_SCHEMA_PATH = ROOT.join('envoy.json')
    SERVIVE_DEFINITION_PATH = ROOT.join('service_definition.json')

    class << self
      def validate_envoy_definition(hash)
        schema = load_schema(ENVOY_SCHEMA_PATH)
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
