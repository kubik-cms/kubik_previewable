# frozen_string_literal: true

require "test_helper"

class KubikPreviewable::CaptureEndpointTest < ActiveSupport::TestCase
  setup do
    @env = ENV.to_h
  end

  teardown do
    ENV.replace(@env)
  end

  test "default ferrum base url uses loopback" do
    ENV.delete("KUBIK_PREVIEW_CAPTURE_BASE_URL")
    ENV.delete("KUBIK_PREVIEW_CAPTURE_USE_PUBLIC_URL")
    ENV["PORT"] = "3000"

    assert_equal "http://127.0.0.1:3000", KubikPreviewable::CaptureEndpoint.ferrum_base_url
  end

  test "request host falls back to PRIMARY_HOST when ferrum uses loopback" do
    ENV.delete("KUBIK_PREVIEW_CAPTURE_HOST")
    ENV.delete("KUBIK_PREVIEW_CAPTURE_BASE_URL")
    ENV["PRIMARY_HOST"] = "cln-staging.example.com"
    ENV["PORT"] = "3000"

    assert_equal "cln-staging.example.com", KubikPreviewable::CaptureEndpoint.request_host
  end

  test "renderer_http_host matches internal puma" do
    ENV["PORT"] = "3000"

    assert_equal "127.0.0.1", KubikPreviewable::CaptureEndpoint.renderer_http_host
  end
end
