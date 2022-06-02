# frozen_string_literal: true

module ActiveAdmin
  module Views
    # Index View for Kubik image gallery
    class IndexAsMediaGallery < ActiveAdmin::Component
      def build(page_presenter, collection)
        @page_presenter = page_presenter
        @collection = collection
        add_class 'media_gallery'
        build_images
      end


      def self.index_name
        'media_gallery'
      end

      def build_images
        turbo_frame id: 'kubik_media_gallery_frame' do
          build_upload_form
        end
        turbo_frame id: 'media_list' do
          @collection.each do |image|
            build_image(image)
          end
        end
      end

      def build_image(image)
        div for: image, class: 'kubik-media-gallery--media_item_container' do
          build_status(image)
          build_preview(image)
          build_additional_info(image)
        end
      end

      def build_status(image)
        div(class: "kubik-media-gallery--media_item_container--status #{image.aasm_state}") do
          div class: 'status' do
            4.times { div class: 'status_marker' }
          end
          text_node link_to('delete',
                            admin_kubik_media_upload_path(image),
                            class: 'material-symbols-outlined kubik-media-gallery--media_item_container--icon',
                            method: :delete, data: { confirm: 'Are you sure?' })
        end
      end

      def build_preview(image)
        file = image.image.present? ? image.image : image.file
        mime_type = file.metadata['mime_type']
        file_type = Hash[ [:type, :format].zip(mime_type.split("/")) ]

        div(class: "kubik-media-gallery--media_item_container--image media_type_#{file_type[:format]}") do
          if file_type[:type] == 'image'
            link_to edit_admin_kubik_media_upload_path(image) do
              image_tag image.admin_image_thumbnail
            end
          else
            link_to edit_admin_kubik_media_upload_path(image), class: 'material-symbols-outlined material-icon' do
              file_type[:format].include?('pdf') ? 'picture_as_pdf' : 'docs'
            end
          end
        end
      end

      def build_additional_info(image)
        file = image.image.present? ? image.image : image.file
        div class: 'kubik-media-gallery--media_item_container--title' do
          file.metadata['filename']
        end
      end

      def build_upload_form
        div(class: 'file_upload_form',
            id: 'kubik-media-gallery--file_upload_form--container',
            'data-controller': 'image_dropzone',
            'data-image_dropzone-text-value': 'Select a file',
            'data-image_dropzone-turbo-value': Mime::Type.lookup_by_extension(:turbo_stream).present?) do
          render 'file_upload_form'
        end
      end
      protected
      def render_blank_slate
        div do
          text_node 'adasd'
        end
      end
    end
  end
end
