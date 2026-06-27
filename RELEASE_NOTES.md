# Release Notes

## Audio Metadata Editor v1.0.0

Audio Metadata Editor v1.0.0 is the first stable local release of LOTECH's native macOS metadata editor.

### Included

- Native macOS folder picker and recursive audio folder browser.
- Metadata reading for supported local audio files through Apple frameworks.
- Metadata editing and automatic save-on-exit for MP3, M4A, and MP4 files.
- MP3 writing standardized to ID3v2.3 with UTF-16 text frames.
- M4A and MP4 writing through AVFoundation MPEG-4 metadata export.
- Album artwork view, replace, paste, drag-and-drop, and remove workflows.
- File rename support from the File Name field while preserving the original extension.
- Sandbox-friendly last-folder restore on app restart.

### Not Included

- No AI features.
- No cloud services.
- No third-party dependencies.
- No automatic internet metadata lookup.
- No batch metadata editor.

### Known Limitations

- WAV, AIFF, AIF, AAC, ALAC, and FLAC files may appear in the browser when readable, but they are read-only in v1.0.0.
- Artwork input is limited to JPG and PNG.
- The app is a local tool and requires user-selected file or folder access.

### Roadmap

- v1.1.0: optional AI Process workflow through the future LOTECH AI SDK.
- v1.2.0: optional Council SDK workflow for multi-role metadata suggestions.
