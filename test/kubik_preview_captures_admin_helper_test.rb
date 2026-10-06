# frozen_string_literal: true

require "test_helper"

class KubikPreviewCapturesAdminHelperTest < ActiveSupport::TestCase
  include Kubik::PreviewCapturesAdminHelper

  test "show panel requires screenshots configured on model" do
    model = Class.new do
      def self.kubik_preview_screenshots_configured?
        false
      end

      def kubik_preview_captures
        []
      end
    end
    record = model.new
    KubikPreviewable.config.preview_screenshots_enabled = true

    assert_not kubik_preview_captures_show_panel?(record)
  end
end
