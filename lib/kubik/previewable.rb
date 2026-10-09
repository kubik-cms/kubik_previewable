# frozen_string_literal: true

module Kubik
  # Previewable module
  module Previewable
    extend ActiveSupport::Concern

    included do
      class_attribute :kubik_preview_screenshot_trigger, default: :published_save
    end

    class_methods do
      attr_reader :kubik_previewable_opts

      def kubik_previewable(opts = {})
        options = {
          preview_enabled: true,
          layout: "layouts/application",
          template: "#{model_name.plural}/show",
          locals: {},
          screenshots: { enabled: false }
        }.deep_merge(opts.deep_symbolize_keys)
        @kubik_previewable_opts = options

        if kubik_preview_screenshots_configured?
          has_many :kubik_preview_captures,
                   as: :previewable,
                   class_name: "Kubik::PreviewCapture",
                   dependent: :destroy

          after_commit :enqueue_kubik_preview_capture_regeneration, on: %i[create update]
        end

        self.kubik_preview_screenshot_trigger = options.dig(:screenshots, :trigger)&.to_sym || :published_save
      end

      def kubik_preview_screenshots_configured?
        kubik_previewable_opts.present? &&
          ActiveModel::Type::Boolean.new.cast(kubik_previewable_opts.dig(:screenshots, :enabled))
      end

      def kubik_preview_screenshots_options
        kubik_previewable_opts.fetch(:screenshots, {})
      end

      def kubik_preview_screenshots_async?
        opt = kubik_preview_screenshots_options[:async]
        return ::KubikPreviewable.config.preview_screenshots_async if opt.nil?

        ActiveModel::Type::Boolean.new.cast(opt)
      end

      def kubik_preview_screenshot_variant_keys
        opts = kubik_preview_screenshots_options
        keys = opts[:variants] || ::KubikPreviewable.config.preview_variants.keys
        keys = Array(keys).map(&:to_sym)
        extra = opts[:extra_variants] || {}
        keys + extra.keys.map(&:to_sym)
      end

      def kubik_preview_variant_config(variant_key)
        key = variant_key.to_sym
        extra = kubik_preview_screenshots_options[:extra_variants] || {}
        global = ::KubikPreviewable.config.preview_variants
        config = extra[key] || global[key]
        raise ArgumentError, "Unknown preview variant: #{variant_key}" unless config

        config.symbolize_keys
      end

      def kubik_preview_screenshot_fields
        custom = kubik_preview_screenshots_options[:fields]
        return Array(custom).map(&:to_sym) if custom.present?

        if respond_to?(:kubik_versionable_field_names)
          kubik_versionable_field_names
        else
          %i[content]
        end
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
      return {} if instance_variable_setting.nil?

      instance_variable_setting.is_a?(Proc) ? instance_variable_setting.call(self) : instance_variable_setting
    end

    def published_for_preview?
      custom = self.class.kubik_preview_screenshots_options[:published_for_preview]
      return custom.call(self) if custom.respond_to?(:call)

      if respond_to?(:published?)
        published?
      else
        true
      end
    end

    def regenerate_kubik_preview_captures!(async: nil, variants: nil)
      Kubik::PreviewCaptureService::Regenerator.regenerate(self, variants: variants, async: async)
    end

    def regenerate_kubik_preview_capture!(variant, async: nil)
      Kubik::PreviewCaptureService::Regenerator.regenerate_variant(self, variant, async: async)
    end

    def reset_stuck_kubik_preview_captures!(older_than: ::KubikPreviewable.config.stuck_processing_threshold)
      kubik_preview_captures.where(status: "processing").where("updated_at < ?", older_than.ago)
                            .update_all(status: "failed", error_message: "Timed out", updated_at: Time.current)
    end

    private

    def enqueue_kubik_preview_capture_regeneration
      return unless self.class.kubik_preview_screenshots_configured?
      return unless ::KubikPreviewable.config.preview_screenshots_enabled?
      return if skip_kubik_preview_capture_enqueue?
      return unless should_regenerate_kubik_preview_captures?

      regenerate_kubik_preview_captures!
    end

    def skip_kubik_preview_capture_enqueue?
      ::KubikPreviewable.config.skip_screenshots_in_test_env && Rails.env.test?
    end

    def should_regenerate_kubik_preview_captures?
      trigger = self.class.kubik_preview_screenshot_trigger
      case trigger
      when :publish_only
        publish_only_regeneration?
      else
        published_save_regeneration?
      end
    end

    def publish_only_regeneration?
      changes = committed_attribute_changes
      if respond_to?(:published_version_id) && changes.key?("published_version_id")
        return true
      end
      if respond_to?(:published_at) && changes.key?("published_at") && published_at.present?
        return true
      end

      false
    end

    def published_save_regeneration?
      return true if publish_only_regeneration?

      changes = committed_attribute_changes
      fields = self.class.kubik_preview_screenshot_fields
      fields.any? { |field| changes.key?(field.to_s) }
    end

    def committed_attribute_changes
      previous_changes.presence || {}
    end
  end
end
