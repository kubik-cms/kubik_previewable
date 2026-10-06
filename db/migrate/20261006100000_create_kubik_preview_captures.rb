# frozen_string_literal: true

class CreateKubikPreviewCaptures < ActiveRecord::Migration[7.2]
  def change
    create_table :kubik_preview_captures do |t|
      t.references :previewable, polymorphic: true, null: false, index: false
      t.string :variant, null: false
      t.integer :viewport_width
      t.integer :viewport_height
      t.string :status, null: false, default: "pending"
      t.text :error_message
      t.datetime :captured_at
      t.timestamps
    end

    add_index :kubik_preview_captures,
              %i[previewable_type previewable_id variant],
              unique: true,
              name: "index_kubik_preview_captures_on_previewable_and_variant"
    add_index :kubik_preview_captures, %i[previewable_type previewable_id],
              name: "index_kubik_preview_captures_on_previewable"
  end
end
