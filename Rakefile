# frozen_string_literal: true

require "bundler/gem_tasks"

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop]

require_relative "test/dummy/config/application"

Rails.application.load_tasks
