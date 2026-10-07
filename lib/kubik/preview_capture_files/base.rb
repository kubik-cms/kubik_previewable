# frozen_string_literal: true

module Kubik
  module PreviewCaptureFiles
    class Base
      def attached?(_capture)
        raise NotImplementedError
      end

      def purge!(_capture)
        raise NotImplementedError
      end

      def attach!(_capture, io:, filename:, content_type:)
        raise NotImplementedError
      end

      def image_tag_source(_capture)
        raise NotImplementedError
      end
    end
  end
end
