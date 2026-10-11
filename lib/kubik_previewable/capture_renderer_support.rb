# frozen_string_literal: true

module KubikPreviewable
  # Include in a host-app renderer helper (e.g. Admin::PublicHtmlRenderer) for Ferrum-friendly
  # ApplicationController.renderer options.
  module CaptureRendererSupport
    module_function

    def capture_screenshot_render?
      KubikPreviewable::CaptureContext.rendering_screenshot
    end

    def renderer_http_host(default_host:)
      return CaptureEndpoint.renderer_http_host if capture_screenshot_render?

      default_host
    end

    def renderer_https?(development: Rails.env.development?, test: Rails.env.test?)
      return false if capture_screenshot_render?

      !development && !test
    end

    def capture_context_http_host
      KubikPreviewable::CaptureContext.http_host if capture_screenshot_render?
    end
  end
end
