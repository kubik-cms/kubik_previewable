# frozen_string_literal: true

module Kubik
  module PreviewCapturesAdminHelper
    def kubik_preview_captures_show_panel?(record)
      return false unless record
      return false unless record.class.respond_to?(:kubik_preview_screenshots_configured?)
      return false unless record.class.kubik_preview_screenshots_configured?
      return false unless ::KubikPreviewable.config.preview_screenshots_enabled?

      true
    end

    def kubik_preview_captures_available?(record)
      record.kubik_preview_captures.any?(&:displayable?)
    end

    def kubik_preview_captures_in_progress?(record)
      record.kubik_preview_captures.in_progress.exists?
    end

    def kubik_preview_captures_stream_name(record)
      "kubik_preview_captures:#{record.class.name}:#{record.id}"
    end

    def kubik_preview_captures_dom_id(record)
      "kubik_preview_captures_#{dom_id(record)}"
    end

    def kubik_render_preview_captures_panel(record)
      render partial: "kubik_previewable/admin/preview_captures_panel", locals: { record: record }
    end

    def kubik_preview_capture_variant_label(record, variant_key)
      record.class.kubik_preview_variant_config(variant_key)[:label] || variant_key.to_s.humanize
    end

    def kubik_regenerate_preview_capture_path(record, variant_key)
      route_key = record.model_name.singular_route_key
      send(:"regenerate_preview_capture_admin_#{route_key}_path", record, variant: variant_key)
    rescue StandardError
      nil
    end

    def kubik_preview_capture_dimensions(capture, record)
      width = capture.viewport_width
      height = capture.viewport_height
      if width.blank? || height.blank?
        config = record.class.kubik_preview_variant_config(capture.variant)
        width = config[:width]
        height = config[:height]
      end
      [width.to_i, height.to_i]
    end

    def kubik_preview_capture_image_tag(capture, record:, **options)
      width, height = kubik_preview_capture_dimensions(capture, record)
      source = Kubik::PreviewCaptureFiles.adapter.image_tag_source(capture)
      source = absolute_preview_capture_image_url(source)
      options = options.dup
      options[:width] = width
      options[:height] = height
      options[:class] = [options[:class], "kubik-preview-captures__image"].compact.join(" ")
      options[:style] = [options[:style], "width: #{width}px; height: #{height}px;"].compact.join(" ")
      image_tag(source, **options)
    end

    def absolute_preview_capture_image_url(source)
      return source unless source.is_a?(String) && source.start_with?("/")
      return source unless defined?(request) && request.present?

      "#{request.base_url}#{source}"
    end

    module_function

    def broadcast_preview_captures_panel(record)
      return unless defined?(Turbo::StreamsChannel)
      return unless record

      helper = Object.new.extend(ActionView::RecordIdentifier).extend(Kubik::PreviewCapturesAdminHelper)
      stream = helper.kubik_preview_captures_stream_name(record)
      target = helper.kubik_preview_captures_dom_id(record)

      Turbo::StreamsChannel.broadcast_replace_to(
        stream,
        target: target,
        partial: "kubik_previewable/admin/preview_captures_inner",
        locals: { record: record }
      )
    end
  end
end
