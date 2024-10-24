# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.string :content

      t.timestamps
    end
  end
end
