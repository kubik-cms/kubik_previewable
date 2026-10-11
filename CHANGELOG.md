## [Unreleased]

## [0.1.5] - 2026-10-12

### Fixed

- Turbo Cable updates for preview screenshots: inner panel partial now keeps a stable DOM id across `broadcast_replace_to`, so “ready” captures refresh the admin UI after async jobs finish.
- Broadcast rendering includes `PreviewCapturesAdminHelper` on `ApplicationController` for background jobs.

## [0.1.4] - 2026-10-12

### Added

- `KubikPreviewable::CAPTURE_RENDER_PATH` for host-app HTTP Basic / host authorization skips.
- `KubikPreviewable::CaptureEndpoint` — default Ferrum loopback URL and capture request host from env (`KUBIK_PREVIEW_CAPTURE_*`, `PRIMARY_HOST`, `ASSET_HOST`).
- Engine initializer to use relative `/assets` URLs while `CaptureContext.rendering_screenshot` is set.
- `KubikPreviewable::CaptureRendererSupport` for host-app `ApplicationController.renderer` options.
- `rake kubik_previewable:preview_capture:debug` (uses `config.render_for_capture`).

### Fixed

- Signed capture tokens with `/` in the payload no longer 404 — token is passed as a query parameter.
- Ferrum capture: HTTP Basic auth, stylesheet wait, configurable timeout, optional debug artifacts.

## [0.1.0] - 2021-06-04

- Initial release
