# frozen_string_literal: true

require "kubik_previewable/configuration"
require "kubik_previewable/capture_context"
require "kubik_previewable/capture_endpoint"
require "kubik_previewable/capture_asset_url_helper"
require "kubik_previewable/capture_renderer_support"
require "kubik_previewable/capture_request_context"
require "kubik_previewable/capture_request_middleware"
require "kubik_previewable/engine"

module KubikPreviewable
  class Error < StandardError; end

  # Path on the mounted engine (skip HTTP Basic / host authorization in host apps).
  CAPTURE_RENDER_PATH = "/kubik_previewable/captures/render"

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      configuration
    end

    def configure
      yield(configuration)
    end
  end
end

module Kubik
  require "kubik/previewable"
  require "kubik/previewable_admin_action"
  require "kubik/preview_captures_admin_helper"
  require "kubik/preview_captures_admin_action"
  require "kubik/preview_capture_files"
  require "kubik/preview_capture/capture_token"
  require "kubik/preview_capture/browser_capture"
  require "kubik/preview_capture/regenerator"
end
