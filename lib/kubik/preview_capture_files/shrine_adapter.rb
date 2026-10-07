# frozen_string_literal: true

module Kubik
  module PreviewCaptureFiles
    class ShrineAdapter < Base
      def attached?(capture)
        capture.image.present?
      end

      def purge!(capture)
        return unless capture.image.present?

        capture.image_attacher.destroy
      end

      def attach!(capture, io:, filename:, content_type:)
        file = io.is_a?(String) ? StringIO.new(io.b) : io
        capture.image_attacher.attach(
          file,
          metadata: { "filename" => filename, "mime_type" => content_type }
        )
        capture.save!
      end

      def image_tag_source(capture)
        capture.image.url
      end
    end
  end
end
