# frozen_string_literal: true

module Kubik
  module PreviewCaptureService
    class BrowserCapture
      def self.capture_variant!(record, variant_key, variant_config)
        require "ferrum"

        url = CaptureToken.capture_url(record)
        browser = Ferrum::Browser.new(browser_options)

        begin
          apply_viewport!(browser, variant_config)
          apply_capture_request_host!(browser)
          browser.goto(url)
          browser.network.wait_for_idle(timeout: 30) if browser.network.respond_to?(:wait_for_idle)

          tempfile = Tempfile.new(["kubik_preview", ".png"])
          browser.screenshot(path: tempfile.path, full: variant_config.fetch(:full_page, true))
          tempfile.rewind
          tempfile.read
        ensure
          browser&.quit
        end
      end

      def self.browser_options
        opts = {
          headless: true,
          timeout: 60,
          process_timeout: 60,
          browser_options: {
            "no-sandbox": nil,
            "disable-dev-shm-usage": nil
          }
        }
        chrome_path = ENV["CHROME_BIN"].presence ||
                      %w[/usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome].find { |p| File.exist?(p) }
        opts[:browser_path] = chrome_path if chrome_path
        opts
      end

      def self.apply_capture_request_host!(browser)
        host = ::KubikPreviewable.config.resolved_capture_request_host
        return if host.blank?

        browser.headers.set("Host" => host)
      end

      def self.apply_viewport!(browser, variant_config)
        width = variant_config.fetch(:width)
        height = variant_config.fetch(:height)
        scale = variant_config[:device_scale_factor]

        if browser.respond_to?(:set_viewport)
          browser.set_viewport(
            width: width,
            height: height,
            scale_factor: scale || 0
          )
        elsif browser.respond_to?(:viewport=)
          vp = scale ? { width: width, height: height, scale: scale } : { width: width, height: height }
          browser.viewport = vp
        else
          browser.resize(width: width, height: height)
        end
      end

      def self.viewport_for(config)
        width = config.fetch(:width)
        height = config.fetch(:height)
        scale = config[:device_scale_factor]
        if scale
          { width: width, height: height, scale: scale }
        else
          { width: width, height: height }
        end
      end
    end
  end
end
