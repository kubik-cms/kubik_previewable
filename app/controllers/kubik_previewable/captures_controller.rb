# frozen_string_literal: true

module KubikPreviewable
  class CapturesController < ActionController::Base
    layout false

    around_action :with_preview_capture_host

    def render_capture
      record = Kubik::PreviewCaptureService::CaptureToken.verify(params[:token])
      return head :not_found unless record

      renderer = KubikPreviewable.config.render_for_capture
      return head :not_implemented unless renderer

      html = renderer.call(record)
      render html: html, layout: false, content_type: "text/html"
    end

    private

    def with_preview_capture_host
      KubikPreviewable::CaptureContext.rendering_screenshot = true
      KubikPreviewable::CaptureContext.http_host =
        KubikPreviewable.config.resolved_capture_request_host.presence || request.host_with_port
      yield
    ensure
      KubikPreviewable::CaptureContext.reset
    end
  end
end
