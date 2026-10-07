# frozen_string_literal: true

module Kubik
  module PreviewCaptureService
    class BrowserCapture
      SCREENSHOT_TIMEOUT = 120
      FULL_PAGE_SCREENSHOT_ERROR = /unable to capture screenshot/i

      def self.capture_variant!(record, variant_key, variant_config)
        require "ferrum"

        url = CaptureToken.capture_url(record)
        browser = Ferrum::Browser.new(browser_options)

        begin
          apply_viewport!(browser, variant_config)
          browser.goto(url)
          wait_for_render!(browser)

          tempfile = Tempfile.new(["kubik_preview", ".png"])
          full_page = variant_config.fetch(:full_page, false)
          screenshot_to_file!(browser, tempfile.path, full: full_page)
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

      def self.wait_for_render!(browser)
        wait_for_network_idle!(browser)
        wait_for_body!(browser)
      end

      def self.wait_for_body!(browser, timeout: 30)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          return if browser.at_css("body")

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            raise Ferrum::TimeoutError, "Timed out waiting for document body"
          end

          sleep 0.1
        end
      end

      def self.wait_for_network_idle!(browser)
        return unless browser.network.respond_to?(:wait_for_idle)

        browser.network.wait_for_idle(timeout: 8)
      rescue Ferrum::TimeoutError, Ferrum::PendingConnectionsError
        # Turbo / Action Cable / analytics can leave idle connections open.
        nil
      end

      def self.screenshot_to_file!(browser, path, full:)
        browser.screenshot(path: path, full: full, timeout: SCREENSHOT_TIMEOUT)
      rescue Ferrum::BrowserError => e
        raise unless full && e.message.to_s.match?(FULL_PAGE_SCREENSHOT_ERROR)

        browser.screenshot(path: path, full: false, timeout: SCREENSHOT_TIMEOUT)
      end

      def self.apply_viewport!(browser, variant_config)
        width = variant_config.fetch(:width)
        height = variant_config.fetch(:height)
        scale = variant_config[:device_scale_factor]

        if browser.respond_to?(:set_viewport)
          if scale
            browser.set_viewport(width: width, height: height, scale_factor: scale)
          else
            browser.set_viewport(width: width, height: height)
          end
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
