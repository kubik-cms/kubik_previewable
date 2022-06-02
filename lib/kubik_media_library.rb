# frozen_string_literal: true
require 'aasm'
require 'acts_as_list'
require 'image_optim'
require 'shrine'
require "kubik_media_library/version"

module KubikMediaLibrary
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace KubikMediaLibrary

      config.assets.precompile += %w( kubik_media_gallery.js )
      initializer :kubik_media_library do
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/arbre']
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/active_admin/views']
        ActiveAdmin.application.load_paths += Dir[File.dirname(__FILE__) + '/kubik_media_library/admin']
      end
    end
  end
end
