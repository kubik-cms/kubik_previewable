# frozen_string_literal: true

module KubikPreviewable
  class Engine < ::Rails::Engine
    isolate_namespace KubikPreviewable

    config.generators do |g|
      g.test_framework :minitest
    end

    initializer "kubik_previewable.migrations" do |app|
      unless app.root.to_s.start_with?(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "kubik_previewable.capture_request_middleware" do |app|
      app.middleware.use KubikPreviewable::CaptureRequestMiddleware
    end

    initializer "kubik_previewable.capture_assets" do |app|
      app.config.to_prepare do
        ActionView::Base.prepend(KubikPreviewable::CaptureAssetUrlHelper)

        original = Rails.application.config.action_controller.asset_host
        next if original.blank?

        Rails.application.config.action_controller.asset_host = lambda do |source, request|
          if KubikPreviewable::CaptureContext.rendering_screenshot
            nil
          elsif original.is_a?(Proc)
            original.call(source, request)
          else
            original
          end
        end
      end
    end

    initializer "kubik_previewable.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Kubik::PreviewCapturesAdminHelper
      end

      # Turbo::StreamsChannel renders via ApplicationController — not only ActiveAdmin pages.
      ActiveSupport.on_load(:action_controller) do
        helper Kubik::PreviewCapturesAdminHelper if respond_to?(:helper)
      end
    end

    initializer "kubik_previewable.active_admin_helpers" do
      config.to_prepare do
        next unless defined?(ActiveAdmin::BaseController)

        ActiveAdmin::BaseController.helper Kubik::PreviewCapturesAdminHelper
      end
    end

    initializer "kubik_previewable.shrine_storages", after: :load_config_initializers do
      next unless KubikPreviewable.config.resolved_preview_capture_storage == :shrine
      next unless defined?(::Shrine) && ::Shrine.respond_to?(:storages) && ::Shrine.storages.present?

      require "kubik/preview_capture/shrine_uploader"
      Kubik::PreviewCaptureImageUploader.storages = ::Shrine.storages
    end

    rake_tasks do
      load root.join("lib/tasks/kubik_previewable_preview_captures.rake")
    end
  end
end
