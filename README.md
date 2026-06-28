# mac-disk-cleanup

A Pi skill for safe, interactive macOS disk cleanup.

Guides you step by step to free disk space without deleting anything without your explicit approval. Covers caches, build artifacts, unused apps, and duplicate `.mp3` conversions from `.m4a` sources.

## Usage

Install the skill in Pi, then ask:

> "Clean up disk space on my Mac."

## Files

- `SKILL.md` — workflow and patterns
- `scripts/cleanup_music_mp3_duplicates.sh` — `.mp3`/`.m4a` duplicate cleanup script

Run the script standalone:

```bash
./scripts/cleanup_music_mp3_duplicates.sh --dry-run ~/Music
./scripts/cleanup_music_mp3_duplicates.sh --delete ~/Music
```
