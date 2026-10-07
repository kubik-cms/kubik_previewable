# frozen_string_literal: true

class AddImageDataToKubikPreviewCaptures < ActiveRecord::Migration[7.2]
  def change
    add_column :kubik_preview_captures, :image_data, :text unless column_exists?(:kubik_preview_captures, :image_data)
  end
end
