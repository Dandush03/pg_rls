# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @tenant_id = SecureRandom.uuid
    @tenant = Tenant.create!(tenant_id: @tenant_id)
    PgRls::Tenant.switch(@tenant)
  end

  test "can create a post" do
    post = Post.new
    assert post.save, "Failed to save the post"
  end

  test "can read a post" do
    post = Post.create!
    found = Post.find_by(id: post.id)
    assert_equal post, found, "Could not find the created post"
  end

  test "can update a post" do
    post = Post.create!
    assert post.save, "Failed to update the post"
  end

  test "can delete a post" do
    post = Post.create!
    assert_difference("Post.count", -1) do
      post.destroy
    end
  end

  test "can create a post with tenant_id" do
    Post.ignored_columns = []
    post = Post.create!
    assert_equal post.reload.tenant_id, @tenant.tenant_id, "Post tenant_id should not be nil"
    Post.ignored_columns += [:tenant_id]
  end

  test "cannot create a post without tenant id" do
    PgRls::Current.reset
    assert_raise ActiveRecord::StatementInvalid do
      Post.create!
    end
  end
end
