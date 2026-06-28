---
name: mac-disk-cleanup
description: Safe, guided macOS disk space cleanup. Use when the user wants to free up disk space on a Mac, clean caches safely, remove unused apps and their data, find large folders, or remove duplicate music files. Interacts with the user one step at a time and never deletes anything without explicit approval.
---

# Mac Disk Cleanup

Guide the user through safe, interactive macOS disk cleanup. Treat disk space, user data, and trust as finite resources: conserve all three.

## When this skill triggers

Trigger on requests like:

- "clean up disk space on my Mac"
- "free up space on macOS"
- "delete caches safely"
- "remove duplicate music files"
- "uninstall [app] and its data"
- "find what's using disk space"

## Core workflow

1. **Establish goals and constraints first.** Ask:
   - How much space do they want to free?
   - Any folders or data types that are off-limits?
   - Do they prefer aggressive or conservative cleanup?
2. **Inspect disk usage.** Run `df -h /System/Volumes/Data` and `du -hd1 ~ | sort -rh | head -20`.
3. **Classify targets.** Label every item as:
   - **Safe/reversible** — rebuildable or pure cache
   - **Review-required** — large, personal, or tied to an active workflow
   - **Never-touch** — system files or explicit user exclusions
4. **Propose one bucket at a time.** Show sizes, what will be removed, and the risk. Wait for explicit approval before any deletion.
5. **Execute, verify, repeat.** Run the deletion, re-measure free space, and ask before moving to the next bucket.
6. **Log and report.** Keep a markdown record of decisions, commands run, and results.

## Reusable target patterns

### Safe/reversible

- **Build artifacts** — any folder that regenerates when the project is built or run.
- **Language runtime caches** — package manager caches for npm, yarn, pnpm, pip, uv, cargo, etc.
- **Old runtime versions** — versions managed by `fnm`, `nvm`, `pyenv`, etc., that are not the default or in active use.
- **Unused app data** — support files, caches, and logs for apps the user has stopped using.
- **Reviewed staging folders** — Downloads, Trash, or temporary folders the user has already inspected.

### Review-required

- **Active project dependencies** — virtual environments, `node_modules`, lock files. Only delete after confirming the project can be rebuilt.
- **Large app data** — downloaded models, media libraries, chat databases. Verify the app is unused before removing.
- **User media duplicates** — music, photos, videos. Use specialized duplicate tools and approve results before deleting.

### Never-touch

- System directories (`/System`, `/Library`, `/usr`, `/bin`, `/sbin`).
- Time Machine local snapshots.
- Any folder or data type the user explicitly excludes.

## App uninstall pattern

For apps the user no longer uses:

1. Check if the app is running.
2. Quit the app.
3. Delete the app bundle from `/Applications`.
4. Delete common user data paths:
   - `~/.cache/<app>`
   - `~/.<app>`
   - `~/Library/Application Support/<App Name>`
   - `~/Library/Caches/<app>`
   - `~/Library/Logs/<App Name>`
5. Empty Trash if the app bundle was moved there.
6. Re-measure free space.

## Media duplicate cleanup

For collections where the user creates alternate-format copies (e.g., `.mp3` from `.m4a`), use a rule-based script to delete the derived copy only when the original exists in the same folder.

Use the bundled script:

```bash
./scripts/cleanup_music_mp3_duplicates.sh --dry-run [folder]
./scripts/cleanup_music_mp3_duplicates.sh --delete  [folder]
```

Default folder is `~/Music`. Always run `--dry-run` first. The script writes a timestamped log to `logs/` for every run.

## Verification commands

```bash
df -h /System/Volumes/Data
du -hd1 ~ | sort -rh | head -20
```

## Communication rules

- **One question at a time.** Never ask for approval on multiple unrelated deletions in one message.
- **Explain before asking.** Tell the user what a path is, why it is safe or risky, and the estimated savings.
- **Show tables.** Present candidates with size, path, and risk level.
- **Confirm explicitly.** Require a clear yes/no before deleting. Do not infer approval from vague answers.
- **Respect terminal access limits.** If a folder is protected by macOS privacy controls, give the user a script or command to run in a native Terminal rather than failing silently.
- **Protect active workflows.** When cleaning project folders, ask whether the project is currently used and whether a rebuild is acceptable.

## User preference learning

During cleanup, watch for and record user preferences:

- Aggressive vs conservative default risk tolerance.
- Folders or data types they always protect.
- Preferred tools (duplicate finders, search tools, scripts).
- Whether they want logs kept and where.
- Whether they prefer terminal commands, scripts, or GUI tools.

Apply these preferences on the next cleanup without re-asking. If unsure, ask.

## Adaptive behavior

- If a scan is slow on an external drive, use non-blocking tools or ask the user to run a script locally.
- If a deletion target is unexpectedly large or risky, pause and re-confirm before proceeding.
- If a script fails because of a typo or access issue, stop, explain, and give the corrected command rather than assuming.
- If a cleanup bucket frees much more or less space than estimated, update assumptions and communicate the real result.

## Example session (reference only)

A real cleanup that followed this pattern:

- Goal: free 20+ GB safely.
- Constraint: never touch system files or delete without permission.
- Buckets approved:
  1. Unused app + data — removed app bundle, `~/.cache/<app>`, `~/Library/Application Support/<App>`, `~/Library/Logs/<App>`.
  2. Safe caches and build output — project build cache, old runtime version, package manager caches.
  3. Media duplicates — deleted derived `.mp3` files whose matching `.m4a` existed in the same folder.
- Result: ~39 GB freed.

Do not assume the same paths apply to every session. Use this example only as a guide for identifying similar patterns.
