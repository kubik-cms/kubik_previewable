# frozen_string_literal: true

namespace :kubik_previewable do
  namespace :preview_captures do
    desc "Regenerate preview captures (CLASS, optional ID). ENV: ASYNC, VARIANTS, BATCH_SIZE"
    task :regenerate, %i[class_name record_id] => :environment do |_t, args|
      async = ActiveModel::Type::Boolean.new.cast(ENV.fetch("ASYNC", "true"))
      variants = ENV["VARIANTS"]&.split(",")&.map(&:strip)&.presence

      if args[:record_id].present?
        record = args[:class_name].constantize.find(args[:record_id])
        Kubik::PreviewCaptureService::Regenerator.regenerate(record, variants: variants, async: async)
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
      Kubik::PreviewCaptureService::Regenerator.regenerate_variant(record, args[:variant], async: async)
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

  namespace :preview_capture do
    desc "Inspect capture HTML, asset URLs, and loopback HTTP (CLASS=Page ID=1)"
    task debug: :environment do
      require "open3"

      renderer = KubikPreviewable.config.render_for_capture
      abort "Set KubikPreviewable.config.render_for_capture in config/initializers/kubik_previewable.rb" unless renderer

      klass_name = ENV.fetch("CLASS", KubikPreviewable.config.previewable_classes.first || "Page")
      record = klass_name.constantize.find(ENV.fetch("ID"))
      base_url = KubikPreviewable.config.resolved_capture_base_url
      request_host = KubikPreviewable.config.resolved_capture_request_host

      puts "=== Kubik preview capture debug ==="
      puts "Record: #{record.class.name}##{record.id}"
      puts "published_for_preview?: #{record.published_for_preview?}" if record.respond_to?(:published_for_preview?)
      puts "Ferrum base URL: #{base_url}"
      puts "Capture request host: #{request_host}"
      puts "ASSET_HOST: #{ENV['ASSET_HOST'].presence || '(unset)'}"
      puts "CHROME_BIN: #{ENV['CHROME_BIN'].presence || '(unset)'}"
      puts "Preview screenshots enabled: #{KubikPreviewable.config.preview_screenshots_enabled?}"
      puts

      KubikPreviewable::CaptureContext.rendering_screenshot = true
      KubikPreviewable::CaptureContext.http_host = request_host
      html = renderer.call(record)
      KubikPreviewable::CaptureContext.reset

      out_dir = Rails.root.join("tmp", "preview_capture_debug")
      FileUtils.mkdir_p(out_dir)
      html_path = out_dir.join("#{klass_name.underscore}_#{record.id}.html")
      File.write(html_path, html)
      puts "Wrote HTML: #{html_path}"

      stylesheets = html.scan(/<link[^>]+rel=["']stylesheet["'][^>]*>/i)
      puts "\nStylesheet tags (#{stylesheets.size}):"
      stylesheets.each { |tag| puts "  #{tag}" }

      hrefs = html.scan(/href=["']([^"']+)["']/).flatten.grep(%r{\.css|/assets/})
      puts "\nCSS / asset hrefs:"
      hrefs.uniq.each { |href| puts "  #{href}" }

      capture_url = Kubik::PreviewCaptureService::CaptureToken.capture_url(record)
      puts "\nSigned capture URL (Ferrum opens this):"
      puts "  #{capture_url}"

      puts "\nLoopback HTTP checks (from this host):"
      check_url = lambda do |label, url|
        cmd = ["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}", url]
        output, status = Open3.capture2(*cmd)
        code = output.to_s.strip
        puts "  #{label}: HTTP #{code}#{status.success? ? '' : ' (curl failed)'}"
      rescue StandardError => e
        puts "  #{label}: error (#{e.message})"
      end

      check_url.call("Capture render", capture_url)
      hrefs.uniq.first(5).each do |href|
        absolute = href.start_with?("http") ? href : "#{base_url.to_s.chomp('/')}#{href}"
        check_url.call("Asset #{href}", absolute)
      end

      puts "\nTo run Ferrum capture in console (may take ~30s):"
      puts "  Kubik::PreviewCaptureService::Regenerator.capture_now!(#{klass_name}.find(#{record.id}), variants: [:desktop])"
      puts "\nWith debug PNG/HTML (KUBIK_PREVIEW_CAPTURE_DEBUG=true):"
      puts "  ls -la #{out_dir}/*"
    end
  end
end
