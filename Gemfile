# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in pg_rls.gemspec
gemspec

gem "rake", "~> 13.0"

group :development, :test do
  gem "rails", "~> 7.2.2"

  # Guard automatically & intelligently launch tests [https://github.com/guard/guard-minitest]
  gem "guard" # NOTE: this is necessary in newer versions
  gem "guard-minitest"

  # Code and Debug Report [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false
  # Code Linting [https://github.com/rubocop/rubocop]
  gem "rubocop", require: false
  # Code Linting Performance optimization analysis [https://github.com/rubocop/rubocop-performance]
  gem "rubocop-performance", require: false
  # Code Linting Rake-specific analysis [https://github.com/rubocop/rubocop-rake]
  gem "rubocop-rake", require: false

  # Database Cleaner [https://github.com/DatabaseCleaner/database_cleaner]
  gem "database_cleaner-active_record"

  # Ruby Strong Typing [https://github.com/ruby/rbs]
  gem "rbs", require: false
  # Ruby Strong Typing Validations [https://github.com/soutaro/steep]
  gem "steep"

  # Ruby vulnerability checker [https://github.com/rubysec/bundler-audit]
  gem "bundler-audit"

  # Reduces boot times through caching; required in config/boot.rb
  gem "bootsnap", require: false
end
