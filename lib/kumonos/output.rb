require 'pathname'

module Kumonos
  # Output manipulation.
  class Output
    def initialize(dir, type, name)
      @dir = Pathname.new(dir)
      @type = type
      @name = name
    end

    def write(json)
      target =
        case @type
        when :clusters
          @dir.join('v1', 'clusters', @name, @name)
        when :routes
          @dir.join('v1', 'routes', Kumonos::DEFAULT_ROUTE_NAME, @name, @name)
        else
          raise %(Unknown type "#{@type}" given)
        end
      target.parent.mkpath unless target.parent.exist?
      target.write(json)
      target
    end
  end
end
