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

    initializer "kubik_previewable.helpers" do
      ActiveSupport.on_load(:action_view) do
        include Kubik::PreviewCapturesAdminHelper
      end
    end

    rake_tasks do
      load root.join("lib/tasks/kubik_previewable_preview_captures.rake")
    end
  end
end
