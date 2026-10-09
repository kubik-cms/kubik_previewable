# frozen_string_literal: true

module Kubik
  module PreviewCapturesAdminAction
    extend ActiveSupport::Concern

    def self.included(base)
      base.send(:member_action, :regenerate_preview_captures, method: :post) do
        resource.regenerate_kubik_preview_captures!
        resource.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              helpers.kubik_preview_captures_inner_dom_id(resource),
              partial: "kubik_previewable/admin/preview_captures_inner",
              locals: { record: resource }
            )
          end
          format.html { redirect_to resource_path, notice: "Preview screenshots queued for regeneration." }
        end
      end

      base.send(:member_action, :regenerate_preview_capture, method: :post) do
        variant = params[:variant]
        resource.regenerate_kubik_preview_capture!(variant)
        resource.reload
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              helpers.kubik_preview_captures_inner_dom_id(resource),
              partial: "kubik_previewable/admin/preview_captures_inner",
              locals: { record: resource }
            )
          end
          format.html { redirect_to resource_path, notice: "Preview screenshot for #{variant} queued." }
        end
      end
    end
  end
end
