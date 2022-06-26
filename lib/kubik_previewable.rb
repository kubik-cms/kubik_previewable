# frozen_string_literal: true

module KubikPreviewable
  class Error < StandardError; end
  # Your code goes here...
end

module Kubik
  require 'kubik/kubik_previewable'
  require 'kubik/preview_shared_admin_actions'
end
