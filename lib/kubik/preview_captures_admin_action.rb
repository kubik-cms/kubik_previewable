# frozen_string_literal: true

module Kubik
  module PreviewCapturesAdminAction
    extend ActiveSupport::Concern

    def self.included(base)
      route_key = base.config.resource_name.singular_route_key
      base_class = base.config.resource_class_name.classify.constantize

      base.send(:member_action, :regenerate_preview_captures, method: :post) do
        resource.regenerate_kubik_preview_captures!
        redirect_to resource_path, notice: "Preview screenshots queued for regeneration."
      end

      base.send(:member_action, :regenerate_preview_capture, method: :post) do
        variant = params[:variant]
        resource.regenerate_kubik_preview_capture!(variant)
        redirect_to resource_path, notice: "Preview screenshot for #{variant} queued."
      end

      base.send(:action_item,
                :regenerate_preview_captures,
                only: %i[show],
                if: proc {
                  base_class.kubik_preview_screenshots_configured? &&
                    ::KubikPreviewable.config.preview_screenshots_enabled? &&
                    helpers.kubik_preview_captures_show_panel?(resource)
                }) do
        link_to "Regenerate previews",
                send(:"regenerate_preview_captures_admin_#{route_key}_path", resource),
                method: :post
      end
    end
  end
end
