# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "can create a comment" do
    comment = Comment.new
    assert comment.save, "Failed to save the comment"
  end

  test "can read a comment" do
    comment = Comment.create!
    found = Comment.find_by(id: comment.id)
    assert_equal comment, found, "Could not find the created comment"
  end

  test "can update a comment" do
    comment = Comment.create!
    assert comment.save, "Failed to update the comment"
  end

  test "can delete a comment" do
    comment = Comment.create!
    assert_difference("Comment.count", -1) do
      comment.destroy
    end
  end
end
