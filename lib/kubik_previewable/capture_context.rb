# frozen_string_literal: true

module KubikPreviewable
  # Request-scoped values while Ferrum loads /kubik_previewable/captures/render (URL helpers, omit chrome).
  class CaptureContext < ActiveSupport::CurrentAttributes
    attribute :http_host
    attribute :rendering_screenshot, default: false
  end
end
