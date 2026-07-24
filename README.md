# LOTECH Audio Metadata Editor

A lightweight macOS application for viewing, organizing, and editing audio metadata, whether it is a single track or a folder of audio files.

LOTECH Audio Metadata Editor combines detailed single-track editing with a spreadsheet-style Batch Edit interface, making audio collections easier to clean up without expensive music management software or technical tag-editor friction.

This app is part of the **LOTECH** family of practical desktop utilities built to reduce friction and help people get real work done.

---

## Why LOTECH Audio Metadata Editor?

Managing audio metadata should feel like managing a spreadsheet, not opening hundreds of individual dialogs.

LOTECH combines:

- Single-file editing for detailed work
- Spreadsheet-style batch editing for folder-level cleanup
- Local processing with no cloud dependency
- A clean native macOS interface
- Practical metadata handling without exposing unnecessary technical complexity

The app handles the metadata details behind the scenes so editing a music library feels more like organizing music and less like editing a database.

---

## Edit Like A Spreadsheet

Editing metadata should not mean opening one song, making a change, saving it, opening the next song, and repeating the process over and over.

Batch Edit lets you work with supported files in a folder using a spreadsheet-style table:

- Scan rows quickly
- Sort columns
- Resize columns
- Select multiple rows
- Apply selected field changes across rows
- Save batch changes only when you are ready

The goal is simple: make repeated metadata edits feel familiar, fast, and controlled.

---

## Single Edit

Single Edit is for focused work on one track.

It shows the selected audio file, editable metadata fields, and album artwork tools in a clean native macOS interface.

Editable single-file fields include:

- File name
- Title
- Artist
- Contributing artist
- Album
- Release year
- Composer
- Genre
- Lyrics
- Description
- Vibe / mood
- Artwork, where supported

---

## Batch Edit

Batch Edit is for folder-level cleanup.

In v1.1.0, Batch Edit supports table-based editing for writable audio files in the selected folder.

Batch Edit features include:

- Sidebar mode switch for Single Edit / Batch Edit
- Folder-scoped table view
- Sortable columns
- Resizable columns
- Multi-row selection
- Right-click batch field editing for selected rows
- Draft changes that are not written until Save Changes is clicked
- Unsaved-change protection before leaving Batch Edit

Batch editable fields include:

- Title
- Artist
- Album
- Year
- Genre

---

## Local First

All metadata editing happens locally on your Mac.

- No audio files are uploaded.
- No cloud processing is required.
- No subscriptions.
- No accounts.
- No hidden AI provider or API key dependency.

Future AI-assisted features, if introduced, will remain optional.

---

## Supported Formats

Writable metadata currently supports:

- MP3
- M4A
- MP4

Some readable formats may appear in the library but remain read-only unless a write path is explicitly supported.

Read-only formats may include:

- WAV
- AIFF / AIF
- AAC
- ALAC
- FLAC

---

## ID3 Handling

MP3 writes use ID3v2.3 with UTF-16 text frames for broad compatibility.

The app replaces known editable frames while preserving unrelated frames where possible. For users, this means MP3 metadata is saved in a practical modern format without needing to choose between ID3 versions manually.

---

## Current Status

Current release: `v1.1.0`

Release headline: Batch Edit mode with spreadsheet-style metadata editing.

Download the latest release:

- [LOTECH Audio Metadata Editor v1.1.0](https://github.com/oonteng/lotech-audio-metadata-editor/releases/tag/v1.1.0)

Current release includes:

- Single Edit mode
- Spreadsheet-style Batch Edit mode
- Folder-scoped batch editing
- Sortable and resizable batch columns
- Selected-row batch field editing
- Artwork editing for supported files
- ID3v2.3 MP3 writing
- M4A / MP4 metadata writing

---

## Known Limitations

- This app is provided as-is.
- Writable metadata depends on the audio format.
- Some readable formats are treated as read-only.
- Batch editing should be done carefully.
- Always test with copied files before editing valuable originals.
- The app is not notarized yet, so macOS may require right-click > Open on first launch.

---

## Roadmap

Future directions include:

- Additional audio formats
- More batch-editable fields
- Batch rename
- Search and filtering
- Undo / redo
- Better artwork workflows
- MusicBrainz lookup
- Optional AI-assisted metadata suggestions
- LOTECH AI SDK integration
- Optional Council SDK workflow

---

## Developer Documentation

- [Architecture](docs/Architecture.md)
- [Metadata handling](docs/Metadata.md)

---

## LOTECH Philosophy

Technology should work the way people think, not the way computers store data.

LOTECH builds focused desktop tools that solve everyday problems without unnecessary complexity.

If software can quietly handle technical complexity for us, it should.

That gives us something more valuable than another feature.

It gives us back our time.

---

## License

Released under the MIT License.

See [LICENSE](LICENSE).

---

## Disclaimer

This software is provided as-is, without warranty of any kind.

The author is not responsible for any data loss, file corruption, metadata damage, loss of artwork, compatibility issues, business loss, or any other direct or indirect damage caused by using this software.

Use this app at your own risk. Back up your audio files before editing.
