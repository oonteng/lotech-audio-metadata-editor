# LOTECH Audio Metadata Editor

Organise and clean up our music library without wrestling with audio metadata.

A lightweight macOS application for viewing, organising and editing audio metadata, whether we're working on a single track or an entire music collection.

LOTECH combines detailed single-track editing with a spreadsheet-style Batch Edit interface, making large music libraries practical to organise without expensive music management software or complicated tag editors.

---

## Download

LOTECH Audio Metadata Editor requires **macOS 14 Sonoma or later**.

### [Latest Release](https://github.com/oonteng/lotech-audio-metadata-editor/releases/latest)

- [**Apple Silicon**](https://github.com/oonteng/lotech-audio-metadata-editor/releases/download/v1.1.0/LOTECH-AudioMetadataEditor-v1.1.0-macOS-AppleSilicon.zip) — Recommended for M1, M2, M3, M4 and later Macs
- [**Universal**](https://github.com/oonteng/lotech-audio-metadata-editor/releases/download/v1.1.0/LOTECH-AudioMetadataEditor-v1.1.0-macOS-Universal.zip) — Works on both Apple Silicon and Intel Macs
- [View the Release Notes](https://github.com/oonteng/lotech-audio-metadata-editor/releases/tag/v1.1.0)
- [Download SHA-256 Checksums](https://github.com/oonteng/lotech-audio-metadata-editor/releases/download/v1.1.0/SHA256SUMS.txt)

### Installation

1. Download the appropriate ZIP file.
2. Double-click the ZIP file to extract **LOTECH Audio Metadata Editor.app**.
3. Move the application into the **Applications** folder.
4. Launch **LOTECH Audio Metadata Editor**.

The current release is not notarized. If macOS displays a security warning on first launch, right-click the application and choose **Open**.

---

## Less time fixing metadata. More time enjoying music.

Music files quietly carry information we rarely think about.

Sometimes album names are inconsistent.

Sometimes artists are split into multiple spellings.

Sometimes genres become a mess after years of downloading, ripping CDs, recording lectures or moving files between different applications.

Cleaning up that information shouldn't require opening hundreds of files one at a time or learning technical tagging standards.

We built LOTECH Audio Metadata Editor because organising our music library should feel simple again.

Technology can deal with the technical details.

We shouldn't have to.

---

## We think about music. Not metadata.

When we look at an audio file, we don't think:

*"Is this ID3?"*

*"Is this MP4 metadata?"*

*"Which tag version is this using?"*

Most of us simply want to know:

- What is this song?
- Who performs it?
- Which album does it belong to?
- When was it released?
- Can we find it again later?

LOTECH presents metadata the way we naturally organise our music.

Behind the scenes, the application quietly reads and writes the appropriate metadata standards while presenting one consistent editing experience.

---

## Edit like a spreadsheet

This is probably our favourite feature.

Editing metadata shouldn't mean opening one song, making a change, clicking **Save**, opening the next song, and repeating the same process hundreds of times.

Instead, LOTECH lets us edit an entire folder the same way many of us already work every day — like a spreadsheet.

Most of us grew up using Word, Excel and PowerPoint. Tables feel natural. We can scan hundreds of rows, sort columns, copy and paste values, and make changes quickly.

So why are we still editing music metadata one file at a time through endless dialog boxes?

We'd rather see everything in one place, make the changes, press **Save**, and get back to enjoying the music.

Simple.

Fast.

Familiar.

---

## Built by someone who had the same problem

This software exists because we had years of music.

Albums collected over decades.

CDs we ripped ourselves.

Songs purchased from different stores.

Voice recordings.

Podcasts.

Lecture recordings.

Sound effects.

We wanted a better way to organise everything.

So we built one.

If it quietly helps someone else organise their own collection too, we've achieved what we set out to do.

---

## Single Edit

Sometimes we only need to work on one audio file.

Maybe we're correcting the title of a favourite song.

Adding album artwork.

Fixing the artist name.

Or cleaning up metadata before sharing the file with someone else.

Single Edit lets us edit metadata while viewing everything about the selected track in one place.

No hunting through multiple dialog boxes.

No guessing which tag field to edit.

Just the information we actually care about.

### Features

- Clean native macOS interface
- Artwork preview and replacement
- Editable metadata fields
- Read-only technical information
- Instant metadata refresh after saving
- Metadata validation

### Editable metadata

- Title
- Artist
- Contributing Artist
- Album
- Album Artist
- Release Year
- Track Number
- Disc Number
- Genre
- Composer
- Comments
- Description
- Lyrics
- Mood / Vibe
- Copyright
- Artwork (where supported)

---

## Batch Edit

This is where LOTECH really shines.

Most music collections don't contain ten songs.

They contain hundreds.

Sometimes thousands.

Fixing metadata one file at a time quickly becomes repetitive and frustrating.

Batch Edit was designed to solve exactly that problem.

Instead of opening one file after another, we simply open a folder and edit everything in a spreadsheet.

The workflow feels familiar because most of us already know how spreadsheets work.

Scan the rows.

Sort the columns.

Select the tracks we want.

Apply the changes.

Save everything together when we're ready.

No changes are written until we choose to save.

That gives us confidence to make large edits without worrying about accidentally changing hundreds of files.

### Features

- Spreadsheet-style editing
- Folder-based workflow
- Sortable columns
- Resizable columns
- Multi-row selection
- Batch field editing
- Draft changes before saving
- Unsaved-change protection
- Fast keyboard navigation

### Batch editable metadata

Current release supports batch editing of:

- Title
- Artist
- Album
- Release Year
- Genre

More fields will be added in future releases.

---

## Artwork Management

Album artwork is part of the listening experience.

It helps us recognise albums at a glance and keeps our music library looking organised.

LOTECH lets us replace or update artwork for supported audio formats without needing a separate tagging application.

The goal isn't to become a dedicated artwork manager.

It's simply to make common tasks feel effortless.

---

## The technical details are still there

Sometimes we do want to inspect the technical side of an audio file.

Codec.

Bitrate.

Sample rate.

Channels.

Duration.

Metadata versions.

No problem.

LOTECH doesn't hide the technical information.

We simply choose not to overwhelm us with everything the moment we open a file.

The information is there when we need it, and quietly stays out of the way when we don't.

---

## Local First

Our music library stays on our computer.

Metadata editing happens locally.

No cloud processing.

No subscriptions.

No accounts.

No hidden AI provider.

No API keys.

Our music collection stays exactly where it belongs.

Future AI-assisted features, if introduced, will always remain optional.

---

## Technical Details

LOTECH Audio Metadata Editor supports the metadata standards used by modern music players, operating systems and audio management software.

### Supported writable formats

- MP3
- M4A
- MP4

### Read-only formats

Some audio formats can be opened for viewing but are currently treated as read-only.

These may include:

- WAV
- AIFF / AIF
- AAC
- ALAC
- FLAC

Support for additional writable formats will continue to expand in future releases.

---

### Metadata compatibility

Metadata is written using widely supported industry standards, making files compatible with applications such as:

- Apple Music
- Finder
- MusicBee
- foobar2000
- MediaMonkey
- Mp3tag
- VLC Media Player
- and many other applications that support standard audio metadata.

For MP3 files, LOTECH writes metadata using **ID3v2.3** with **UTF-16** text encoding to maximise compatibility across different operating systems and music players.

Whenever possible, only the editable metadata fields are updated while unrelated metadata is preserved.

---

## Current Status

Current release includes:

- Single Edit mode
- Spreadsheet-style Batch Edit
- Folder-scoped editing
- Sortable columns
- Resizable columns
- Multi-row selection
- Batch field editing
- Artwork editing for supported formats
- Draft changes before saving
- Unsaved-change protection
- MP3 metadata writing
- M4A / MP4 metadata writing

---

## Known Limitations

- Writable metadata depends on the audio format.
- Some supported formats are currently read-only.
- Artwork support varies between audio formats.
- Different music players may display metadata differently depending on the metadata standard they support.
- Always keep backups before performing large batch operations.

---

## Roadmap

Future directions include:

- Support for additional writable audio formats
- More batch-editable metadata fields
- Batch rename
- Search
- Filters
- Undo / Redo
- Smarter artwork management
- MusicBrainz lookup
- Optional AI-assisted metadata suggestions
- LOTECH Metadata Engine
- LOTECH AI SDK integration

Our goal isn't to become the most feature-rich audio tag editor.

Our goal is to remove the friction from organising our music library, one practical improvement at a time.

---

## About LOTECH

LOTECH builds practical software that quietly removes friction from everyday work.

We don't chase trends.

We don't build software simply because a new technology appears.

We build software because we ran into a real problem ourselves and believed there had to be a better way.

Many of our projects begin with the same question:

*"Why is this still so difficult?"*

Sometimes the answer is decades of legacy software.

Sometimes it's complicated workflows that everyone has simply learned to tolerate.

Sometimes it's software that exposes technical complexity instead of quietly handling it.

That's where LOTECH comes in.

We quietly solve annoying problems that many of us have simply learned to live with.

Instead of adding more technology, we try to make technology disappear into the background so we can focus on the work itself.

We don't build software to impress people.

We build software that quietly helps us finish the job.

Technology can deal with the technical details.

We shouldn't have to.

---

## Part of the LOTECH family

LOTECH Audio Metadata Editor is part of a growing collection of focused, local-first desktop applications built around the same philosophy.

Current projects include:

- LOTECH Photo Metadata Editor
- LOTECH Audio Metadata Editor
- LOTECH Text Editor

More focused tools are on the way.

Every application is designed with the same goal:

Reduce friction.

Respect our privacy.

Stay fast.

Stay simple.

Help us get real work done.

---

## License

Released under the **MIT License**.

See the **LICENSE** file for details.

---

## Disclaimer

This software is provided **as-is**, without warranty of any kind.

Although every effort has been made to keep metadata handling safe and reliable, different audio formats and media players may interpret metadata differently.

We strongly recommend keeping backups of valuable audio files before performing large batch edits.

The author shall not be liable for any loss of data, file corruption, metadata incompatibility, artwork loss, business interruption or any other direct or indirect damages arising from the use of this software.

Use this application at your own risk.

---

## Acknowledgements

LOTECH Audio Metadata Editor is built with appreciation for the many open standards and open-source projects that have made modern metadata handling possible.

Their work allows applications like this to remain compatible across different operating systems, music players and media management software.

Thank you to everyone who contributes to making open software better.

---

## Thank You

Thank you for trying LOTECH Audio Metadata Editor.

We hope it quietly makes organising your music library just a little easier.

If it saves us even a few minutes every time we clean up our collection, then it has already achieved exactly what we built it to do.
