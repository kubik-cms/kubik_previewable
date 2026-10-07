# frozen_string_literal: true

module KubikPreviewable
  class CaptureRequestMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      CaptureRequestContext.http_request = true
      @app.call(env)
    ensure
      CaptureRequestContext.http_request = false
    end
  end
end
