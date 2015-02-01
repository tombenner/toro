require File.expand_path('../lib/toro/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ['Tom Benner']
  s.email         = ['tombenner@gmail.com']
  s.description = s.summary = %q{Transparent, extensible background processing for Ruby & PostgreSQL}
  s.homepage      = 'https://github.com/tombenner/toro'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.name          = 'toro'
  s.require_paths = ['lib']
  s.version       = Toro::VERSION
  s.license       = 'MIT'

  s.add_dependency 'celluloid', '>= 0.15.2'
  s.add_dependency 'rails', '>= 3.0'
  s.add_dependency 'pg'
  s.add_dependency 'activerecord-postgres-hstore'
  s.add_dependency 'nested-hstore'

  # Monitor
  s.add_dependency 'slim'
  s.add_dependency 'jquery-datatables-rails', '>= 2.1.10.0.2'
  s.add_dependency 'rails-datatables'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rspec'
end
