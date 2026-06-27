# Metadata Handling

The app is designed as a local metadata editor. It reads metadata through Apple frameworks and writes only formats that have an explicit save path.

## Writable Formats

- MP3
- M4A
- MP4

## Read-Only Formats

Some formats can be scanned and read when macOS can load their metadata, but are treated as read-only in v1.0.0:

- WAV
- AIFF / AIF
- AAC
- ALAC
- FLAC

## MP3

MP3 writes use ID3v2.3 with UTF-16 text frames for broad compatibility.

The writer replaces known editable frames while preserving unrelated frames where possible. Artwork is written through ID3 attached picture frames.

## M4A and MP4

M4A and MP4 files do not use ID3 tags. They are written through native MPEG-4 metadata handling with AVFoundation passthrough export.

Known editable metadata atoms are replaced while unrelated metadata is preserved where possible.

## Local-Only Scope

The v1.0.0 app does not include AI metadata generation, cloud sync, online metadata lookup, or hidden provider dependencies.
