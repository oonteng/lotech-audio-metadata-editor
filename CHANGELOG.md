# CHANGELOG

## 1.1.0

- Added Batch Edit mode.
- Added a Batch Edit entry above the folder tree in the sidebar.
- Added a table-based metadata editor for supported writable audio files.
- Added draft tracking, discard, reload, and save controls for batch edits.
- Added a prompt before leaving Batch Edit with unsaved changes.
- Added spreadsheet-style sorting to the Batch Edit table.
- Added right-click batch field editing for selected rows.
- Changed Batch Edit folder selection to show only direct writable audio files in the selected folder.
- Kept v1.0.0 single-file editing behavior intact.

## 1.0.0

- First public release.
- Added native macOS folder selection and recursive audio file browsing.
- Added local metadata reading through Apple frameworks.
- Added metadata editing for MP3, M4A, and MP4 files.
- Added MP3 ID3v2.3 writing with UTF-16 text frames.
- Added native MPEG-4 metadata writing for M4A and MP4 files.
- Added album artwork preview, replacement, paste, drag-and-drop, and removal.
- Added file renaming while preserving the original extension.
- Added sandbox-friendly last-folder restore.
- Marked readable but unsupported write formats as read-only.
- Confirmed the first release is local-only, with no AI provider, cloud service, or API key requirement.
