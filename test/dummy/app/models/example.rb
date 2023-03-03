# frozen_string_literal: true

# Dummy Class for testing

class Example < ApplicationRecord
  include ::Kubik::Previewable
  kubik_previewable
end
