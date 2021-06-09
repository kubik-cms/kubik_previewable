# frozen_string_literal: true

module Slickr
  # SharedAdminActions module
  module SharedAdminActions
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def self.included(base)
      route_key = base.config.resource_name.singular_route_key
      base_class = base.config.resource_class_name.classify.constantize
      base.send(:action_item,
                :"preview_#{route_key}",
                only: %i[edit show],
                method: :get,
                if: proc {
                  base_class.respond_to?(:slickr_previewable_opts) &&
                  base_class.slickr_previewable_opts &&
                  base_class.slickr_previewable_opts[:preview_enabled]
                }) do
        link_to "Preview",
                send("preview_#{route_key}_admin_#{route_key}_path"),
                target: "_blank"
      end

      ###############
      # Member actions
      ###############

      base.send(:member_action,
                :"preview_#{route_key}",
                method: :get) do
        resource.slickr_previewable_instance_variables.each do |name, value|
          instance_variable_set("@#{name}", value)
        end
        render layout: resource.slickr_previewable_layout,
               template: resource.slickr_previewable_template,
               locals: resource.slickr_previewable_locals
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
