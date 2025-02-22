# frozen_string_literal: true

require "test_helper"
require "generators/pg_rls/active_record/active_record_generator"

# rubocop:disable Metrics/ClassLength
class ActiveRecordGeneratorTest < Rails::Generators::TestCase
  tests PgRls::Generators::ActiveRecordGenerator
  destination File.expand_path("../tmp", __dir__)

  setup do
    prepare_destination
  end

  def run_default_generator(args = ["User"], options = {})
    PgRls::Generators::ActiveRecordGenerator.new(args, options, { destination_root: destination_root })
  end

  test "it creates the model file" do
    run_generator ["User"]
    assert_file "app/models/user.rb", /class User < ApplicationRecord/
  end

  test "it creates a migration file" do
    run_generator ["User", "--migration", "true"]

    migration_files = Dir.entries("#{destination_root}/db/migrate")
    migration_file = migration_files.find do |f|
      f.include?("create_pg_rls_users") || f.include?("create_pg_rls_tenant_users")
    end

    assert migration_file, "Expected migration file to be created"
  end

  test "it does not generate an abstract class if it already exists" do
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
    File.write(File.join(destination_root, "app/models/abstract_base_class.rb"),
               "class AbstractBaseClass < ApplicationRecord\nend")

    run_generator ["User"]

    assert_file "app/models/abstract_base_class.rb", "class AbstractBaseClass < ApplicationRecord\nend"
  end

  test "it generates an abstract class if it does not exist" do
    run_generator ["User", "--database", "postgres"]

    assert_file "app/models/postgres_record.rb"
  end

  test "it changes the parent class" do
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
    File.write(File.join(destination_root, "app/models/user.rb"), "class User < ApplicationRecord\nend")

    run_generator ["User", "--parent", "CustomApplicationRecord", "--force"]

    assert_file "app/models/user.rb", /class User < CustomApplicationRecord/
  end

  test "it cleans indexes attributes if needed" do
    attribute = Struct.new(:reference?, :has_index?, :attr_options).new(true, false, { index: true })

    generator = run_default_generator(["User"], { indexes: false })
    generator.instance_variable_set(:@attributes, [attribute])
    generator.send(:clean_indexes_attributes!)

    assert_nil attribute.attr_options[:index]
  end

  test "it returns true if the model file exists" do
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
    File.write(File.join(destination_root, "app/models/user.rb"), "class User < ApplicationRecord\nend")

    generator = run_default_generator
    assert generator.send(:model_file_exists?)
  end

  test "it returns false if the model file does not exist" do
    FileUtils.rm_rf(File.join(destination_root, "app/models"))

    generator = run_default_generator
    assert_not generator.send(:model_file_exists?)
  end

  test "it upgrades the model file" do
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
    File.write(File.join(destination_root, "app/models/user.rb"), "class User < ApplicationRecord\nend")

    generator = run_default_generator(["User"], { parent: "PgRlsApplicationRecord" })
    generator.define_singleton_method(:class_coalescing?) { true }
    assert generator.send(:model_file_exists?)

    generator.send(:upgrade_model_file)

    assert_file "app/models/user.rb" do |content|
      assert_match(/class User < PgRlsApplicationRecord/, content)
    end
  end

  test "it sets @class_coalescing to true when a class collision occurs" do
    Object.const_set(:User, Class.new)

    generator = run_default_generator
    generator.send(:check_class_collision)

    assert_equal true, generator.instance_variable_get(:@class_coalescing)

    Object.send(:remove_const, "User")
  end

  test "it creates a migration file with the correct prefix" do
    generator = run_default_generator

    generator.define_singleton_method(:class_coalescing?) { true }
    generator.define_singleton_method(:skip_migration_creation?) { false }

    generator.send(:upgrade_migration_file)

    migration_prefix = generator.send(:migration_template_prefix)

    expected_migration_file = if migration_prefix == "pg_rls_tenant"
                                "db/migrate/convert_to_pg_rls_tenant_users.rb"
                              else
                                "db/migrate/convert_to_pg_rls_users.rb"
                              end

    assert_migration expected_migration_file
  end

  test "it creates a backport migration file" do
    generator = run_default_generator

    generator.define_singleton_method(:class_coalescing?) { true }
    generator.define_singleton_method(:skip_migration_creation?) { false }
    generator.define_singleton_method(:installing?) { false }

    generator.send(:backport_migration_file)

    assert_migration "db/migrate/backport_pg_rls_to_users.rb"
  end

  test "rls_parent returns the correct value" do
    generator = run_default_generator(["User"], { rls_parent: "CustomRlsRecord" })
    assert_equal "CustomRlsRecord", generator.send(:rls_parent)
  end

  test "parent_class_name returns the correct value" do
    generator = run_default_generator(["User"], { rls_parent: "CustomRlsRecord" })
    generator.define_singleton_method(:installing?) { false }
    assert_equal "CustomRlsRecord", generator.send(:parent_class_name)

    generator = run_default_generator(["User"], { rls_parent: "CustomRlsRecord" })
    generator.define_singleton_method(:installing?) { true }
    assert_equal "ApplicationRecord", generator.send(:parent_class_name)

    generator = run_default_generator(["User"])
    generator.define_singleton_method(:installing?) { true }
    assert_equal "ApplicationRecord", generator.send(:parent_class_name)
  end
end
# rubocop:enable Metrics/ClassLength
