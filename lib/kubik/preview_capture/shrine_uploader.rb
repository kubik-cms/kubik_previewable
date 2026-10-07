# frozen_string_literal: true

require "shrine"

module Kubik
  class PreviewCaptureImageUploader < ::Shrine
    plugin :activerecord
    plugin :determine_mime_type

    Attacher.validate do
      validate_max_size 15 * 1024 * 1024, message: "is too large (max 15 MB)"
      validate_mime_type %w[image/png image/jpeg image/webp]
    end

  end
end
