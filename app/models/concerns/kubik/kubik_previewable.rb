# frozen_string_literal: true

module Kubik
  # Previewable module
  module KubikPreviewable
    extend ActiveSupport::Concern

    # Previewable class level methods
    class_methods do
      attr_reader :kubik_previewable_opts

      private

      def kubik_previewable(opts = {})
        options = {
          preview_enabled: true,
          layout: "layouts/application",
          template: "#{model_name.plural}/show",
          locals: {}
        }.merge(opts)
        @kubik_previewable_opts = options
      end
    end

    def kubik_previewable_locals
      locals_setting = self.class.kubik_previewable_opts[:locals]
      locals_setting.is_a?(Proc) ? locals_setting.call(self) : locals_setting
    end

    def kubik_previewable_layout
      layout_setting = self.class.kubik_previewable_opts[:layout]
      layout_setting.is_a?(Proc) ? layout_setting.call(self) : layout_setting
    end

    def kubik_previewable_template
      template_setting = self.class.kubik_previewable_opts[:template]
      template_setting.is_a?(Proc) ? template_setting.call(self) : template_setting
    end

    def kubik_previewable_instance_variables
      instance_variable_setting = self.class.kubik_previewable_opts[:instance_variables]
      return [] if instance_variable_setting.nil?

      instance_variable_setting.is_a?(Proc) ? instance_variable_setting.call(self) : instance_variable_setting
    end
  end
end
