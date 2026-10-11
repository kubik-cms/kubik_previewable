# frozen_string_literal: true

require "test_helper"

class Kubik::PreviewCaptureService::CaptureTokenTest < ActiveSupport::TestCase
  test "capture_url puts signed token in query string so slashes do not break routing" do
    token_with_slash = "BAh7CDoPY2xhc3NfbmFtZUkiEE5ld3NBcnRpY2xlBjoGRUY6B2lkaQg6CGV4cGwrB/AczGo=--deadbeef"
    record = Struct.new(:class, :id).new(Struct.new(:name).new("NewsArticle"), 3)

    Kubik::PreviewCaptureService::CaptureToken.stub(:generate, token_with_slash) do
      url = Kubik::PreviewCaptureService::CaptureToken.capture_url(record)
      assert_includes url, "#{KubikPreviewable::CAPTURE_RENDER_PATH}?"
      assert_not_includes url, "#{KubikPreviewable::CAPTURE_RENDER_PATH}/#{token_with_slash}"
      assert_includes url, "token=#{Rack::Utils.escape(token_with_slash)}"
    end
  end
end
