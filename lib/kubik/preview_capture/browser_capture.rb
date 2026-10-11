# frozen_string_literal: true

require "fileutils"

module Kubik
  module PreviewCaptureService
    class BrowserCapture
      SCREENSHOT_TIMEOUT = 120
      FULL_PAGE_SCREENSHOT_ERROR = /unable to capture screenshot/i

      def self.capture_timeout
        ENV.fetch("KUBIK_PREVIEW_CAPTURE_TIMEOUT", 120).to_i
      end

      def self.capture_variant!(record, variant_key, variant_config)
        require "ferrum"

        url = CaptureToken.capture_url(record)
        browser = Ferrum::Browser.new(browser_options)
        apply_http_basic_auth!(browser)

        begin
          apply_viewport!(browser, variant_config)
          browser.goto(url)
          wait_for_render!(browser)
          dump_debug_artifacts!(browser, record, variant_key) if preview_capture_debug?

          tempfile = Tempfile.new(["kubik_preview", ".png"])
          full_page = variant_config.fetch(:full_page, false)
          screenshot_to_file!(browser, tempfile.path, full: full_page)
          tempfile.rewind
          tempfile.read
        ensure
          browser&.quit
        end
      end

      def self.apply_http_basic_auth!(browser)
        user = ENV["HTTP_BASIC_USER"].presence
        pass = ENV["HTTP_BASIC_PASSWORD"].presence
        return unless user && pass

        browser.network.authorize(user: user, password: pass) { |req| req.continue }
      end

      def self.browser_options
        timeout = capture_timeout
        opts = {
          headless: true,
          timeout: timeout,
          process_timeout: timeout,
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

      def self.preview_capture_debug?
        ActiveModel::Type::Boolean.new.cast(ENV["KUBIK_PREVIEW_CAPTURE_DEBUG"])
      end

      def self.dump_debug_artifacts!(browser, record, variant_key)
        dir = Rails.root.join("tmp", "preview_capture_debug")
        FileUtils.mkdir_p(dir)
        base = "#{record.class.name.underscore}_#{record.id}_#{variant_key}"
        File.write(dir.join("#{base}.html"), browser.body.to_s)
        browser.screenshot(path: dir.join("#{base}.png").to_s, full: false)
        File.write(dir.join("#{base}.url.txt"), browser.current_url.to_s)
        Rails.logger.info("[kubik_preview_capture] debug artifacts written to #{dir}")
      rescue StandardError => e
        Rails.logger.warn("[kubik_preview_capture] debug dump failed: #{e.message}")
      end

      def self.wait_for_render!(browser)
        wait_for_network_idle!(browser)
        wait_for_body!(browser)
        wait_for_stylesheets!(browser)
      end

      def self.wait_for_stylesheets!(browser, timeout: 20)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          loaded = browser.evaluate(<<~JS)
            (function() {
              var links = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
              if (links.length === 0) return document.styleSheets.length > 0;
              return links.every(function(link) {
                try {
                  return link.sheet && link.sheet.cssRules && link.sheet.cssRules.length > 0;
                } catch (e) {
                  return link.href && link.href.length > 0;
                }
              });
            })();
          JS
          return if loaded

          raise Ferrum::TimeoutError, "Timed out waiting for stylesheets" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          sleep 0.15
        end
      rescue Ferrum::TimeoutError
        raise if preview_capture_debug?

        nil
      end

      def self.wait_for_body!(browser, timeout: nil)
        timeout ||= capture_timeout
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
        loop do
          return if browser.at_css("body")

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            current_url = browser.current_url if browser.respond_to?(:current_url)
            raise Ferrum::TimeoutError,
                  "Timed out waiting for document body (url: #{current_url || 'unknown'})"
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
