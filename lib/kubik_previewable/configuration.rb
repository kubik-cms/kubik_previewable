# frozen_string_literal: true

module KubikPreviewable
  class Configuration
    DEFAULT_VARIANTS = {
      desktop: { width: 1440, height: 900, label: "Desktop", full_page: true },
      laptop: { width: 1280, height: 800, label: "Laptop", full_page: true },
      mobile: { width: 390, height: 844, label: "Mobile", full_page: true, device_scale_factor: 3 }
    }.freeze

    attr_accessor :preview_screenshots_enabled,
                  :capture_base_url,
                  :capture_request_host,
                  :render_for_capture,
                  :preview_screenshots_async,
                  :preview_variants,
                  :previewable_classes,
                  :skip_screenshots_in_test_env,
                  :capture_token_ttl,
                  :stuck_processing_threshold

    def initialize
      @preview_screenshots_enabled = false
      @capture_base_url = nil
      @capture_request_host = nil
      @render_for_capture = nil
      @preview_screenshots_async = true
      @preview_variants = DEFAULT_VARIANTS.deep_dup
      @previewable_classes = []
      @skip_screenshots_in_test_env = true
      @capture_token_ttl = 5.minutes
      @stuck_processing_threshold = 15.minutes
    end

    def preview_screenshots_enabled?
      value = @preview_screenshots_enabled
      value = value.call if value.respond_to?(:call)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def resolved_capture_base_url
      value = @capture_base_url
      value = value.call if value.respond_to?(:call)
      value.to_s.presence
    end

    def resolved_capture_request_host
      value = @capture_request_host
      value = value.call if value.respond_to?(:call)
      value.to_s.presence
    end
  end
end
