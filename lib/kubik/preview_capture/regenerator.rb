# frozen_string_literal: true

module Kubik
  module PreviewCaptureService
    class Regenerator
      class << self
        def regenerate(record, variants: nil, async: nil)
          return unless record.class.kubik_preview_screenshots_configured?

          variant_keys = normalize_variants(record, variants)
          if async.nil?
            async = resolve_async_flag(record)
          end

          variant_keys.each { |variant_key| mark_capture_processing!(record, variant_key) }
          Kubik::PreviewCapturesAdminHelper.broadcast_preview_captures_panel(record)

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
          storage = Kubik::PreviewCaptureFiles.adapter
          storage.purge!(capture)
          storage.attach!(
            capture,
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

        # Ferrum must not run inside the same Puma thread that is serving the admin
        # request; it needs another thread to render /kubik_previewable/captures/render.
        def resolve_async_flag(record)
          if ::KubikPreviewable::CaptureRequestContext.http_request
            return true
          end

          record.class.kubik_preview_screenshots_async?
        end

        def normalize_variants(record, variants)
          keys = variants.presence || record.class.kubik_preview_screenshot_variant_keys
          keys.map(&:to_sym)
        end

        def mark_capture_processing!(record, variant_key)
          config = record.class.kubik_preview_variant_config(variant_key)
          find_or_build_capture(record, variant_key, config).update!(status: "processing", error_message: nil)
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
