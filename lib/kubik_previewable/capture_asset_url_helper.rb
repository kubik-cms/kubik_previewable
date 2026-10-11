# frozen_string_literal: true

module KubikPreviewable
  # Force relative /assets paths while CaptureContext.rendering_screenshot is set so Ferrum
  # on loopback does not fetch ASSET_HOST URLs (often behind HTTP Basic or HTTPS hairpin issues).
  module CaptureAssetUrlHelper
    def compute_asset_host(source = "", options = {})
      return nil if KubikPreviewable::CaptureContext.rendering_screenshot

      super
    end
  end
end
