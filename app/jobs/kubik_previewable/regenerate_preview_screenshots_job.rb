# frozen_string_literal: true

module KubikPreviewable
  class RegeneratePreviewScreenshotsJob < ApplicationJob
    queue_as :default

    def perform(class_name, record_id, variant_keys = nil)
      record = class_name.constantize.find_by(id: record_id)
      return unless record
      return unless record.class.kubik_preview_screenshots_configured?
      return unless record.published_for_preview?

      keys = variant_keys.presence || record.class.kubik_preview_screenshot_variant_keys.map(&:to_s)
      keys.each do |variant_key|
        Kubik::PreviewCapture::Regenerator.capture_single_variant!(record, variant_key)
      end
    end
  end
end
