# frozen_string_literal: true

namespace :kubik_previewable do
  namespace :preview_captures do
    desc "Regenerate preview captures (CLASS, optional ID). ENV: ASYNC, VARIANTS, BATCH_SIZE"
    task :regenerate, %i[class_name record_id] => :environment do |_t, args|
      async = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ASYNC", "true"))
      variants = ENV["VARIANTS"]&.split(",")&.map(&:strip)&.presence

      if args[:record_id].present?
        record = args[:class_name].constantize.find(args[:record_id])
        Kubik::PreviewCapture::Regenerator.regenerate(record, variants: variants, async: async)
        puts "Queued regeneration for #{record.class.name}##{record.id}"
      else
        Kubik::PreviewCapture.regenerate_all_for_class!(args[:class_name], variants: variants, async: async)
        puts "Queued regeneration for all #{args[:class_name]} records"
      end
    end

    desc "Regenerate one variant (CLASS, ID, VARIANT)"
    task :regenerate_variant, %i[class_name record_id variant] => :environment do |_t, args|
      async = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ASYNC", "true"))
      record = args[:class_name].constantize.find(args[:record_id])
      Kubik::PreviewCapture::Regenerator.regenerate_variant(record, args[:variant], async: async)
      puts "Queued #{args[:variant]} for #{record.class.name}##{record.id}"
    end

    desc "Backfill all registered previewable classes"
    task backfill: :environment do
      async = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ASYNC", "true"))
      only_failed = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ONLY_FAILED", "false"))

      if only_failed
        Kubik::PreviewCapture.regenerate_stale_or_failed!(async: async)
        puts "Requeued stale/failed captures"
      else
        KubikPreviewable.config.previewable_classes.each do |klass_name|
          Kubik::PreviewCapture.regenerate_all_for_class!(klass_name, async: async)
          puts "Backfill enqueued for #{klass_name}"
        end
      end
    end
  end
end
