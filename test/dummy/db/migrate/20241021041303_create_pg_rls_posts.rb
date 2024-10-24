# frozen_string_literal: true

class CreatePgRlsPosts < ActiveRecord::Migration[7.2]
  def change
    create_rls_table :posts do |t|
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
