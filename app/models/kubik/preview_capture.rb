# frozen_string_literal: true

module Kubik
  class PreviewCapture < ApplicationRecord
    self.table_name = "kubik_preview_captures"

    STATUSES = %w[pending processing ready failed].freeze

    belongs_to :previewable, polymorphic: true

    Kubik::PreviewCaptureFiles.apply_model_attachments!(self)

    validates :variant, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :ready, -> { where(status: "ready") }
    scope :failed, -> { where(status: "failed") }
    scope :in_progress, -> { where(status: %w[pending processing]) }

    after_commit :broadcast_admin_panel_refresh, on: %i[create update]

    def ready?
      status == "ready"
    end

    def in_progress?
      status.in?(%w[pending processing])
    end

    def displayable?
      ready? && Kubik::PreviewCaptureFiles.adapter.attached?(self)
    end

    def broadcast_admin_panel_refresh
      return unless previewable

      Kubik::PreviewCapturesAdminHelper.broadcast_preview_captures_panel(previewable)
    end

    class << self
      def regenerate_for(record, **options)
        Kubik::PreviewCaptureService::Regenerator.regenerate(record, **options)
      end

      def bulk_regenerate(scope:, variants: nil, async: true, batch_size: 100, **options)
        Kubik::PreviewCaptureService::Regenerator.bulk_regenerate(
          scope: scope,
          variants: variants,
          async: async,
          batch_size: batch_size,
          **options
        )
      end

      def regenerate_all_for_class!(class_name, **options)
        klass = class_name.to_s.constantize
        scope = klass.all
        scope = scope.where.not(published_at: nil) if klass.column_names.include?("published_at")
        bulk_regenerate(scope: scope, **options)
      end

      def regenerate_stale_or_failed!(older_than: ::KubikPreviewable.config.stuck_processing_threshold, **options)
        stuck = where(status: "processing").where("updated_at < ?", older_than.ago)
        stuck.find_each { |capture| capture.update!(status: "failed", error_message: "Timed out") }

        failed_ids = failed.pluck(:previewable_type, :previewable_id).uniq
        failed_ids.each do |type, id|
          record = type.constantize.find_by(id: id)
          regenerate_for(record, **options) if record
        end
      end
    end
  end
end
