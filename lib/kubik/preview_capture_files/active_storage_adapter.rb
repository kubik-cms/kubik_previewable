# frozen_string_literal: true

module Kubik
  module PreviewCaptureFiles
    class ActiveStorageAdapter < Base
      def attached?(capture)
        capture.image.attached?
      end

      def purge!(capture)
        capture.image.purge if capture.image.attached?
      end

      def attach!(capture, io:, filename:, content_type:)
        capture.image.attach(io: io, filename: filename, content_type: content_type)
      end

      def image_tag_source(capture)
        capture.image
      end
    end
  end
end
