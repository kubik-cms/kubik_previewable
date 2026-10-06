# frozen_string_literal: true

module KubikPreviewable
  # Request-scoped host for HTML rendered during Ferrum capture (URL helpers, constraints).
  class CaptureContext < ActiveSupport::CurrentAttributes
    attribute :http_host
  end
end
