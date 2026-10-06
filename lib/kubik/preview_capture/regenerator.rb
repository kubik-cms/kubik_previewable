# frozen_string_literal: true

module Kubik
  module PreviewCaptureService
    class Regenerator
      class << self
        def regenerate(record, variants: nil, async: nil)
          return unless record.class.kubik_preview_screenshots_configured?
          return unless record.published_for_preview?

          variant_keys = normalize_variants(record, variants)
          if async.nil?
            async = record.class.kubik_preview_screenshots_async?
          end

          if async
            ::KubikPreviewable::RegeneratePreviewScreenshotsJob.perform_later(
              record.class.name,
              record.id,
              variant_keys.map(&:to_s)
            )
          else
            ::KubikPreviewable::RegeneratePreviewScreenshotsJob.perform_now(
              record.class.name,
              record.id,
              variant_keys.map(&:to_s)
            )
          end
        end

        def regenerate_variant(record, variant, async: nil)
          regenerate(record, variants: [variant], async: async)
        end

        def capture_now!(record, variants: nil)
          variant_keys = normalize_variants(record, variants)
          variant_keys.each do |variant_key|
            capture_single_variant!(record, variant_key)
          end
        end

        def capture_single_variant!(record, variant_key)
          config = record.class.kubik_preview_variant_config(variant_key)
          capture = find_or_build_capture(record, variant_key, config)

          capture.update!(status: "processing", error_message: nil)
          Kubik::PreviewCapturesAdminHelper.broadcast_preview_captures_panel(record)

          png = BrowserCapture.capture_variant!(record, variant_key, config)
          capture.image.purge if capture.image.attached?
          capture.image.attach(
            io: StringIO.new(png),
            filename: "#{record.class.model_name.singular}_#{record.id}_#{variant_key}.png",
            content_type: "image/png"
          )
          capture.update!(status: "ready", captured_at: Time.current, error_message: nil)
        rescue StandardError => e
          capture&.update!(status: "failed", error_message: e.message)
          raise
        ensure
          Kubik::PreviewCapturesAdminHelper.broadcast_preview_captures_panel(record) if record
        end

        def bulk_regenerate(scope:, variants: nil, async: true, batch_size: 100, published_only: true, **)
          scope.find_in_batches(batch_size: batch_size) do |batch|
            batch.each do |record|
              next if published_only && record.respond_to?(:published_for_preview?) && !record.published_for_preview?

              regenerate(record, variants: variants, async: async)
            end
          end
        end

        private

        def normalize_variants(record, variants)
          keys = variants.presence || record.class.kubik_preview_screenshot_variant_keys
          keys.map(&:to_sym)
        end

        def find_or_build_capture(record, variant_key, config)
          Kubik::PreviewCapture.find_or_initialize_by(
            previewable: record,
            variant: variant_key.to_s
          ).tap do |capture|
            capture.viewport_width = config[:width]
            capture.viewport_height = config[:height]
            capture.status ||= "pending"
          end.tap(&:save!)
        end
      end
    end
  end
end
