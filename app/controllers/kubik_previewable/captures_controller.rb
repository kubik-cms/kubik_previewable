# frozen_string_literal: true

module KubikPreviewable
  class CapturesController < ActionController::Base
    layout false

    def render_capture
      record = Kubik::PreviewCapture::CaptureToken.verify(params[:token])
      return head :not_found unless record
      return head :forbidden unless record.published_for_preview?

      renderer = KubikPreviewable.config.render_for_capture
      return head :not_implemented unless renderer

      html = renderer.call(record)
      render html: html, layout: false, content_type: "text/html"
    end
  end
end
