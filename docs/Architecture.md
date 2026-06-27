# Architecture

LOTECH Audio Metadata Editor is a native SwiftUI macOS app built around a small MVVM structure.

## Structure

```text
LOTECH Audio Metadata Editor/
  App/
  Models/
  Services/
  ViewModels/
  Views/
  Resources/
  Utilities/
```

## Responsibilities

- `App/` contains the SwiftUI app entry point.
- `Models/` contains value types for files, metadata, and editable fields.
- `Services/` contains file browsing, bookmark persistence, artwork loading, metadata reading, metadata writing, file renaming, and text normalization.
- `ViewModels/` coordinates UI state and user actions.
- `Views/` contains SwiftUI and AppKit-backed presentation components.
- `Resources/` contains bundled assets such as the app icon.
- `Utilities/` contains small shared helpers.

## Design Notes

- Views stay presentation-focused.
- File and metadata behavior lives in services.
- The main view model coordinates folder access, selection, reading, writing, artwork updates, and rename flow.
- The app uses Apple's native APIs and does not require third-party packages.
- The sandbox is enabled, with user-selected read-write file access.
