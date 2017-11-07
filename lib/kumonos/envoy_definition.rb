module Kumonos
  EnvoyDefinition = Struct.new(:version, :ds, :statsd, :listener, :admin) do
    class << self
      def from_hash(h)
        ds = symbolize_keys(h.fetch('ds'))
        convert_tls_option!(ds.fetch(:cluster))

        new(
          h.fetch('version'),
          ds,
          convert_tls_option!(symbolize_keys(h.fetch('statsd', {}))),
          symbolize_keys(h.fetch('listener')),
          symbolize_keys(h.fetch('admin'))
        )
      end

      private

      def convert_tls_option!(cluster)
        tls = cluster.delete(:tls)
        cluster[:ssl_context] = {} if tls
        cluster
      end

      def symbolize_keys(hash)
        new = hash.map do |k, v|
          [
            k.to_sym,
            v.is_a?(Hash) ? symbolize_keys(v) : v
          ]
        end
        new.to_h
      end
    end
  end
end
