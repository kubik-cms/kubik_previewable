# frozen_string_literal: true

KubikPreviewable::Engine.routes.draw do
  get "captures/render/:token", to: "captures#render_capture", as: :render_capture
end
