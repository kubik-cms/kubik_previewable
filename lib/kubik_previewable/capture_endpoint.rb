# frozen_string_literal: true

module KubikPreviewable
  # Default Ferrum loopback URL and request-host resolution when the host app does not
  # set config.capture_base_url / config.capture_request_host.
  module CaptureEndpoint
    module_function

    def ferrum_base_url
      explicit_base_url.presence || default_base_url
    end

    def request_host
      ENV["KUBIK_PREVIEW_CAPTURE_HOST"].presence || default_request_host
    end

    # Host:port for ApplicationController.renderer during capture (same origin as Ferrum URL).
    def renderer_http_host
      uri = URI.parse(internal_puma_base_url)
      if uri.port.nil? || uri.port == uri.default_port
        uri.host
      else
        "#{uri.host}:#{uri.port}"
      end
    rescue URI::InvalidURIError
      "127.0.0.1:#{ENV.fetch('PORT', 3000)}"
    end

    def explicit_base_url
      ENV["KUBIK_PREVIEW_CAPTURE_BASE_URL"].presence
    end

    def default_base_url
      if use_public_url?
        deployed = deployed_site_base_url
        return deployed if deployed.present?
      end

      internal = internal_puma_base_url
      return internal if internal.present?

      port = ENV.fetch("PORT", 3000)
      local_host = ENV["LOCAL_HOST"].presence

      if local_host&.end_with?(".localhost")
        return "http://#{local_host}:#{port}"
      end

      "http://127.0.0.1:#{port}"
    end

    def default_request_host
      base = explicit_base_url.presence || default_base_url
      host_with_port = request_host_from_base_url(base)
      return host_with_port if host_with_port.present?

      public_site_host.presence || loopback_request_host
    end

    def internal_puma_base_url
      port = ENV.fetch("PORT", 3000)
      "http://127.0.0.1:#{port}"
    end

    def public_site_host
      ENV["KUBIK_PREVIEW_CAPTURE_HOST"].presence ||
        ENV["PRIMARY_HOST"].presence ||
        host_from_asset_host
    end

    def host_from_asset_host
      asset = ENV["ASSET_HOST"].presence&.chomp("/")
      return if asset.blank?

      URI.parse(asset).host
    rescue URI::InvalidURIError
      nil
    end

    def loopback_request_host
      local_host = ENV["LOCAL_HOST"].presence
      return unless local_host

      port = ENV.fetch("PORT", 3000)
      "#{local_host}:#{port}"
    end

    def deployed_site_base_url
      return nil unless defined?(Rails) && (Rails.env.staging? || Rails.env.production?)

      asset_host = ENV["ASSET_HOST"].presence&.chomp("/")
      return asset_host if asset_host.present?

      host = ENV["PRIMARY_HOST"].presence
      return nil if host.blank?

      protocol = ENV.fetch("APP_PROTOCOL", "https")
      "#{protocol}://#{host}"
    end

    def request_host_from_base_url(base_url)
      return if base_url.blank?

      uri = URI.parse(base_url)
      host = uri.host
      return if host.blank? || loopback_host?(host)

      if uri.port.nil? || uri.port == uri.default_port
        host
      else
        "#{host}:#{uri.port}"
      end
    rescue URI::InvalidURIError
      nil
    end

    def loopback_host?(host)
      host == "127.0.0.1" || host == "localhost" || host.end_with?(".localhost")
    end

    def use_public_url?
      ActiveModel::Type::Boolean.new.cast(ENV["KUBIK_PREVIEW_CAPTURE_USE_PUBLIC_URL"])
    end
  end
end
