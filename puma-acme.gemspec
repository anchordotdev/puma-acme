# frozen_string_literal: true

require_relative 'lib/puma/acme/version'

Gem::Specification.new do |s|
  s.name        = 'puma-acme'
  s.version     = Puma::Acme::VERSION
  s.summary     = 'Puma plugin for ACME.'
  s.description = "A Puma webserver plugin for automatic access to certificates from Let's Encrypt and any other ACME-based CA."
  s.authors     = ['Anchor Security, Inc']
  s.homepage    = 'https://github.com/anchordotdev/puma-acme'
  s.license     = 'MIT'

  s.metadata['homepage_uri']          = s.homepage
  s.metadata['rubygems_mfa_required'] = 'true'

  s.require_paths         = ['lib']
  s.required_ruby_version = '>= 2.5'

  s.files            = Dir['{lib}/**/*'].to_a
  s.files           += ['LICENSE.txt', 'README.md', 'CHANGELOG.md', 'Gemfile', 'Gemfile.lock', 'Rakefile']
  s.extra_rdoc_files = ['LICENSE.txt', 'README.md', 'CHANGELOG.md']

  s.add_runtime_dependency 'acme-client', '~> 2.0.13'
  s.add_runtime_dependency 'pstore', '~> 0.1'
  s.add_runtime_dependency 'puma', '~> 6.0'
  s.add_runtime_dependency 'sinatra', '>= 3.2'

  s.add_development_dependency 'http.rb', '~> 0.12'
  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'minitest-mock_expectations', '~> 1.2'
  s.add_development_dependency 'r509', '~> 1.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'vcr', '~> 6.1'
  s.add_development_dependency 'webmock', '~> 3.19'
end
