# LOTECH Audio Metadata Editor

A simple macOS audio metadata editor built for everyday users who want to clean up MP3 ID3 tags without dealing with technical settings.

This app is part of the **LOTECH** project: small, practical tools built to reduce friction, automate boring work, and help one person operate with more leverage.

## Part of the LOTECH family

This application is part of the LOTECH family of practical software tools.

LOTECH is a growing collection of thoughtfully designed utilities that help people accomplish everyday tasks with less friction. Each tool is intended to be simple, local-first where possible, and useful without unnecessary complexity.

## What it does

LOTECH Audio Metadata Editor lets you view and edit common audio metadata such as:

- Title
- Artist
- Album
- Track number
- Year
- Genre
- Comment
- Artwork, where supported
- Table-based batch edits for supported files

It is designed to be simple, local, and beginner-friendly.

## ID3 handling

The app automatically converts older ID3 metadata to **ID3v2** when saving MP3 files.

This is intentional.

Many novice users do not know, or should not need to know, the difference between ID3v1, ID3v2.3, ID3v2.4, or other technical tag formats. The app chooses a modern, practical default so users can focus on fixing their music library instead of adjusting technical settings.

## Supported use

This app is intended for personal audio file management.

Before batch editing, always keep a backup of important files.

## LOTECH philosophy

LOTECH stands for building small, useful technology that solves real everyday problems.

The aim is not to create bloated software with every possible option. The aim is to create simple tools that work, remove friction, and help users get things done with less mental load.

The app keeps metadata editing local and non-AI by design.

Future versions may add optional AI-assisted metadata suggestions, but users will be expected to provide their own AI provider or API key. This project will not hide cloud cost inside a “free” app.

## Current status

Version: `1.1.0`

The current version adds Batch Edit mode with sidebar mode tabs, table-based metadata editing, selected-row batch field changes, sortable and resizable columns, and folder-scoped editing.

## Known limitations

- This app is provided as-is.
- Not all audio formats support writable metadata.
- Some readable formats may be treated as read-only.
- Batch editing should be done carefully.
- Always test with copied files before editing valuable originals.

## Developer notes

- [Architecture](docs/Architecture.md)
- [Metadata handling](docs/Metadata.md)

## Disclaimer

This software is provided **as-is**, without warranty of any kind.

The author is not responsible for any data loss, file corruption, metadata damage, loss of artwork, compatibility issues, business loss, or any other direct or indirect damage caused by using this software.

Use this app at your own risk.

Please back up your audio files before editing.

## Roadmap

Planned future directions:

- Better artwork handling
- More metadata fields
- AI Process for metadata suggestions
- LOTECH AI SDK integration
- Optional Council SDK workflow for higher-quality metadata reasoning

## License

This project is released under the MIT License.

See `LICENSE` for details.
