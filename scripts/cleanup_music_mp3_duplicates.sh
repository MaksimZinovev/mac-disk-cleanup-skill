#!/usr/bin/env bash
#
# cleanup-music-mp3-duplicates.sh
#
# Purpose: Find .mp3 files in ~/Music that have a matching .m4a with the same
# base name in the SAME folder. These .mp3 files are typically conversions of
# Apple Music .m4a files and can be safely deleted after review.
#
# Usage:
#   chmod +x cleanup-music-mp3-duplicates.sh
#   ./cleanup-music-mp3-duplicates.sh --dry-run   # list candidates only
#   ./cleanup-music-mp3-duplicates.sh --delete    # delete after confirmation
#
# Safe guards:
#   - only checks .mp3 files
#   - only deletes if same-base-name .m4a exists in the same directory
#   - --delete mode asks for explicit y/N confirmation

set -euo pipefail

DEFAULT_DIR="$HOME/Music"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/cleanup-$(date +%Y%m%d-%H%M%S).log"

log() {
	local msg="$1"
	echo "$msg" | tee -a "$LOG_FILE"
}

# Parse arguments
MODE=""
MUSIC_DIR=""

for arg in "$@"; do
	case "$arg" in
	--dry-run | --delete)
		MODE="$arg"
		;;
	--help | -h)
		echo "Usage: $0 [--dry-run|--delete] [path]"
		echo "  path       folder to scan (default: $DEFAULT_DIR)"
		echo "  --dry-run  list .mp3 candidates that have matching .m4a"
		echo "  --delete   delete those .mp3 files after confirmation"
		exit 0
		;;
	-*)
		echo "Unknown option: $arg"
		echo "Usage: $0 [--dry-run|--delete] [path]"
		exit 1
		;;
	*)
		if [[ -z "$MUSIC_DIR" ]]; then
			MUSIC_DIR="$arg"
		else
			echo "Only one path allowed."
			exit 1
		fi
		;;
	esac
done

MUSIC_DIR="${MUSIC_DIR:-$DEFAULT_DIR}"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--delete" ]]; then
	log "Usage: $0 [--dry-run|--delete] [path]"
	log "  path       folder to scan (default: $DEFAULT_DIR)"
	log "  --dry-run  list .mp3 candidates that have matching .m4a"
	log "  --delete   delete those .mp3 files after confirmation"
	exit 1
fi

log "=== Run started at $(date) ==="
log "Mode: $MODE"
log "Scanned directory: $MUSIC_DIR"

if [[ ! -d "$MUSIC_DIR" ]]; then
	log "Error: directory not found: $MUSIC_DIR"
	exit 1
fi

CANDIDATES=()
TOTAL_SIZE=0

{
	log "Candidate list:"
	while IFS= read -r -d '' mp3; do
		dir="$(dirname "$mp3")"
		base="$(basename "$mp3" .mp3)"

		# macOS filesystem is case-insensitive but keep both checks for safety
		if [[ -f "$dir/$base.m4a" || -f "$dir/$base.M4A" ]]; then
			size=$(stat -f%z "$mp3")
			TOTAL_SIZE=$((TOTAL_SIZE + size))
			CANDIDATES+=("$mp3")
			printf '%10s  %s\n' "$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")" "$mp3" | tee -a "$LOG_FILE"
		fi
	done < <(find "$MUSIC_DIR" -type f -iname "*.mp3" -print0)
}

COUNT=${#CANDIDATES[@]}
TOTAL_HUMAN=$(numfmt --to=iec "$TOTAL_SIZE" 2>/dev/null || echo "$TOTAL_SIZE")

log ""
log "Scanned directory: $MUSIC_DIR"
log "Found $COUNT .mp3 candidate(s) with matching .m4a in the same folder."
log "Total size: $TOTAL_HUMAN"

if [[ "$MODE" == "--delete" && "$COUNT" -gt 0 ]]; then
	log ""
	log "WARNING: This will permanently delete the listed .mp3 files."
	read -p "Type 'yes' to proceed, anything else to cancel: " confirm
	log "User confirmation: $confirm"
	if [[ "$confirm" == "yes" ]]; then
		log "Deleting candidates..."
		for mp3 in "${CANDIDATES[@]}"; do
			rm -v "$mp3" | tee -a "$LOG_FILE"
		done
		log ""
		log "Deleted $COUNT file(s), freed ~$TOTAL_HUMAN."
	else
		log "Cancelled. No files deleted."
		exit 0
	fi
fi

log ""
log "=== Run finished at $(date) ==="
log "Log saved to: $LOG_FILE"
