# frozen_string_literal: true

require_relative "lib/pg_rls/version"

Gem::Specification.new do |spec|
  spec.name = "pg_rls"
  spec.version = PgRls::VERSION
  spec.authors = ["Daniel Laloush"]
  spec.email = ["d.laloush@outlook.com"]

  spec.summary = "Write a short summary, because RubyGems requires one."
  spec.description = <<-MSG
    This gem will help you to integrate PostgreSQL RLS to help you develop a great multitenancy application
    checkout the repository at https://github.com/Dandush03/pg_rls
  MSG
  spec.homepage = "https://github.com/Dandush03/pg_rls"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Dandush03/pg_rls"
  spec.metadata["changelog_uri"] = "https://github.com/Dandush03/pg_rls/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile .gem_rbs_collection/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.license = "MIT"

  spec.add_dependency "activerecord", ">= 7.2.2", "< 9.0"
  spec.add_dependency "pg", "~> 1.2"
  spec.add_dependency "railties", ">= 7.2", "< 9.0"
  spec.add_dependency "warden", "~> 1.2"
end
