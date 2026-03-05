#!/bin/bash
# Extract audio from a video file using ffmpeg.
# Usage: extract_audio.sh <input_video> <output_audio> [start_time] [end_time] [bitrate]
#
# Arguments:
#   input_video  - Path to the input video file
#   output_audio - Path to the output audio file (format determined by extension)
#   start_time   - Optional start time (HH:MM:SS or seconds)
#   end_time     - Optional end time (HH:MM:SS or seconds)
#   bitrate      - Optional audio bitrate (e.g., 192k, 320k)

set -euo pipefail

INPUT="$1"
OUTPUT="$2"
START_TIME="${3:-}"
END_TIME="${4:-}"
BITRATE="${5:-192k}"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT" >&2
    exit 1
fi

# Build ffmpeg command
FFMPEG_ARGS=(-y -hide_banner -loglevel warning)

# Add start time if specified
if [ -n "$START_TIME" ]; then
    FFMPEG_ARGS+=(-ss "$START_TIME")
fi

# Input file
FFMPEG_ARGS+=(-i "$INPUT")

# Add end time if specified (as duration or absolute time)
if [ -n "$END_TIME" ]; then
    if [ -n "$START_TIME" ]; then
        FFMPEG_ARGS+=(-to "$END_TIME")
    else
        FFMPEG_ARGS+=(-to "$END_TIME")
    fi
fi

# Audio-only output with specified bitrate
FFMPEG_ARGS+=(-vn -b:a "$BITRATE" "$OUTPUT")

echo "Extracting audio from: $(basename "$INPUT")"
echo "Output: $(basename "$OUTPUT")"
[ -n "$START_TIME" ] && echo "Start time: $START_TIME"
[ -n "$END_TIME" ] && echo "End time: $END_TIME"
echo "Bitrate: $BITRATE"
echo ""

ffmpeg "${FFMPEG_ARGS[@]}"

# Report output file info
if [ -f "$OUTPUT" ]; then
    SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null || stat -f%z "$OUTPUT" 2>/dev/null || echo "unknown")
    DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT" 2>/dev/null || echo "unknown")
    echo ""
    echo "Audio extraction complete:"
    echo "  File: $(basename "$OUTPUT")"
    echo "  Size: $SIZE bytes"
    echo "  Duration: ${DURATION}s"
else
    echo "Error: Output file was not created" >&2
    exit 1
fi
