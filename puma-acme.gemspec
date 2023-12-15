# frozen_string_literal: true

require_relative 'lib/puma-acme/version'

Gem::Specification.new do |s|
  s.name        = 'puma-acme'
  s.version     = Puma::Plugin::Acme::VERSION
  s.summary     = 'Puma plugin for ACME.'
  s.description = "A Puma webserver plugin for automatic access to certificates from Let's Encrypt and any other ACME-based CA."
  s.authors     = ['Anchor Security, Inc']
  s.homepage    = 'https://github.com/anchordotdev/puma-acme'
  s.license     = 'MIT'

  s.metadata['homepage_uri']          = s.homepage
  s.metadata['rubygems_mfa_required'] = 'true'

  s.require_paths         = ['lib']
  s.required_ruby_version = '>= 2.3'

  s.files            = Dir['{lib}/**/*'].to_a
  s.files           += ['LICENSE.txt', 'README.md', 'CHANGELOG.md', 'Gemfile', 'Gemfile.lock', 'Rakefile']
  s.extra_rdoc_files = ['LICENSE.txt', 'README.md', 'CHANGELOG.md']

  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'rake', '~> 13.0'
end
