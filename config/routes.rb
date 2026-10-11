# frozen_string_literal: true

KubikPreviewable::Engine.routes.draw do
  # Signed tokens may contain "/" — do not use a single path segment (:token).
  get "captures/render", to: "captures#render_capture", as: :render_capture
end
