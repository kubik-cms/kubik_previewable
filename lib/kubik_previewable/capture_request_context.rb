# frozen_string_literal: true

module KubikPreviewable
  # Set while a Rack request is being served (see engine middleware).
  # Preview capture must not run Ferrum inline on the same Puma thread.
  class CaptureRequestContext < ActiveSupport::CurrentAttributes
    attribute :http_request
  end
end
