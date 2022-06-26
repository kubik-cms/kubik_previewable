# frozen_string_literal: true

ActiveAdmin.register Example do
  include Kubik::PreviewSharedAdminActions
  permit_params :dummy_title, :dummy_description
end
