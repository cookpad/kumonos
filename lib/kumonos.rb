# frozen_string_literal: true

require 'json'
require 'yaml'

require 'kumonos/version'
require 'kumonos/schemas'
require 'kumonos/envoy'
require 'kumonos/routes'
require 'kumonos/clusters'
require 'kumonos/output'

# Kumonos
module Kumonos
  DEFAULT_ROUTE_NAME = 'default'.freeze
end
