# frozen_string_literal: true

module Kubik
  module PreviewCaptureService
    module CaptureToken
      module_function

      def generate(record)
        payload = {
          class_name: record.class.name,
          id: record.id,
          exp: ::KubikPreviewable.config.capture_token_ttl.from_now.to_i
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
        base = browser_capture_base_url
        "#{base}/kubik_previewable/captures/render/#{token}"
      end

      # Ferrum/Chromium rejects a custom Host header when it does not match the navigation URL
      # (net::ERR_INVALID_ARGUMENT). Apply capture_request_host by rewriting the URL authority.
      # Ferrum must open a URL reachable from Chromium (loopback / Docker service).
      # Public browser hostnames belong in capture_request_host (CaptureContext only).
      def browser_capture_base_url
        ::KubikPreviewable.config.resolved_capture_base_url.to_s.chomp("/")
      end

      def verifier
        Rails.application.message_verifier("kubik_preview_capture")
      end
    end
  end
end
