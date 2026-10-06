# frozen_string_literal: true

module Kubik
  module PreviewCapture
    module CaptureToken
      module_function

      def generate(record)
        payload = {
          class_name: record.class.name,
          id: record.id,
          exp: KubikPreviewable.config.capture_token_ttl.from_now.to_i
        }
        verifier.generate(payload)
      end

      def verify(token)
        payload = verifier.verify(token)
        raise ActiveSupport::MessageVerifier::InvalidSignature unless payload.is_a?(Hash)

        data = payload.with_indifferent_access
        raise ActiveSupport::MessageVerifier::InvalidSignature if data[:exp].to_i < Time.current.to_i

        record = data[:class_name].constantize.find_by(id: data[:id])
        raise ActiveSupport::MessageVerifier::InvalidSignature unless record

        record
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end

      def capture_url(record)
        token = generate(record)
        base = KubikPreviewable.config.capture_base_url.to_s.chomp("/")
        "#{base}/kubik_previewable/captures/render/#{token}"
      end

      def verifier
        Rails.application.message_verifier("kubik_preview_capture")
      end
    end
  end
end
