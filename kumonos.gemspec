lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kumonos/version'

Gem::Specification.new do |spec|
  spec.name          = 'kumonos'
  spec.version       = Kumonos::VERSION
  spec.authors       = ['Taiki Ono']
  spec.email         = ['taiks.4559@gmail.com']

  spec.summary       = 'A "control plane" for Microservices "service mesh".'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/taiki45/kumonos'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'json-schema'
  spec.add_dependency 'jsonnet'
  spec.add_dependency 'thor'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'grpc'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rack'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-json_matcher'
  spec.add_development_dependency 'rubocop'
end
