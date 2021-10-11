# frozen_string_literal: true

require_relative 'lib/pg_rls/version'

Gem::Specification.new do |spec|
  spec.name          = 'pg_rls'
  spec.version       = PgRls::VERSION
  spec.authors       = ['Daniel Laloush']
  spec.email         = ['daniel.laloush@influitive.com']

  spec.summary       = 'Write a short summary, because RubyGems requires one.'
  spec.description = <<-MSG
    This gem will help you to integrate PostgreSQL RLS to help you develop a great multitenancy application
    checkout the repository at https://github.com/Dandush03/pg_rls
  MSG
  spec.homepage      = 'https://github.com/Dandush03/pg_rls'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'bundler', '>= 2.2.10'
  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
