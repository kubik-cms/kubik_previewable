# frozen_string_literal: true

module Kubik
  module PreviewCaptureFiles
    module_function

    def adapter
      @adapter = nil if @adapter_key != current_key
      @adapter_key = current_key
      @adapter ||= build(resolved_backend)
    end

    def resolved_backend
      ::KubikPreviewable.config.resolved_preview_capture_storage
    end

    def build(backend)
      require "kubik/preview_capture_files/base"
      case backend
      when :active_storage, "active_storage"
        require "kubik/preview_capture_files/active_storage_adapter"
        ActiveStorageAdapter.new
      when :shrine, "shrine"
        require "kubik/preview_capture_files/shrine_adapter"
        ShrineAdapter.new
      when Class
        backend.new
      else
        raise ArgumentError, "Unknown preview capture storage: #{backend.inspect}"
      end
    end

    def apply_model_attachments!(model_class)
      backend = resolved_backend
      case backend
      when :active_storage, "active_storage"
        model_class.has_one_attached :image
      when :shrine, "shrine"
        require "kubik/preview_capture/shrine_uploader"
        model_class.include Kubik::PreviewCaptureImageUploader::Attachment(:image)
      when Class
        unless backend.respond_to?(:apply_model_attachments!)
          raise ArgumentError, "Custom preview capture storage must implement apply_model_attachments!"
        end

        backend.apply_model_attachments!(model_class)
      else
        raise ArgumentError, "Unknown preview capture storage: #{backend.inspect}"
      end
    end

    def current_key
      resolved_backend
    end
  end
end
