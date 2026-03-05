#!/bin/bash
# Extract sampled frames from a video file using ffmpeg.
# Does NOT extract every frame by default — always requires explicit sampling.
#
# Usage: extract_frames.sh <input_video> <output_dir> <mode> [param] [format] [quality]
#
# Modes:
#   interval <seconds>  - Extract one frame every N seconds (default: 5)
#   count <N>           - Extract exactly N evenly-spaced frames
#   keyframes           - Extract only keyframes (I-frames)
#
# Arguments:
#   input_video - Path to the input video file
#   output_dir  - Directory to save extracted frames
#   mode        - Extraction mode: interval, count, or keyframes
#   param       - Mode parameter (interval seconds or frame count)
#   format      - Output format: jpg or png (default: jpg)
#   quality     - JPEG quality 1-100 (default: 85, only for jpg)

set -euo pipefail

INPUT="$1"
OUTPUT_DIR="$2"
MODE="${3:-interval}"
PARAM="${4:-5}"
FORMAT="${5:-jpg}"
QUALITY="${6:-85}"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Get video duration and fps for calculations
DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$INPUT" 2>/dev/null || echo "0")
FPS=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$INPUT" 2>/dev/null || echo "30/1")

echo "Extracting frames from: $(basename "$INPUT")"
echo "Duration: ${DURATION}s"
echo "Mode: $MODE"
echo "Format: $FORMAT"
echo ""

# Build quality args
QUALITY_ARGS=""
if [ "$FORMAT" = "jpg" ] || [ "$FORMAT" = "jpeg" ]; then
    QUALITY_ARGS="-qscale:v $(( (100 - QUALITY) * 31 / 100 + 1 ))"
fi

case "$MODE" in
    interval)
        INTERVAL="$PARAM"
        echo "Sampling interval: every ${INTERVAL}s"
        ffmpeg -y -hide_banner -loglevel warning \
            -i "$INPUT" \
            -vf "fps=1/${INTERVAL}" \
            $QUALITY_ARGS \
            "${OUTPUT_DIR}/frame_%05d.${FORMAT}"
        ;;
    count)
        COUNT="$PARAM"
        echo "Extracting $COUNT evenly-spaced frames"
        # Calculate the select expression for evenly spaced frames
        if [ "$COUNT" -le 0 ]; then
            echo "Error: Count must be positive" >&2
            exit 1
        fi
        ffmpeg -y -hide_banner -loglevel warning \
            -i "$INPUT" \
            -vf "select='not(mod(n\,$(echo "$DURATION * $FPS / $COUNT" | bc -l | cut -d. -f1)))',setpts=N/TB" \
            -frames:v "$COUNT" \
            $QUALITY_ARGS \
            "${OUTPUT_DIR}/frame_%05d.${FORMAT}"
        ;;
    keyframes)
        echo "Extracting keyframes (I-frames) only"
        ffmpeg -y -hide_banner -loglevel warning \
            -i "$INPUT" \
            -vf "select='eq(pict_type\,I)'" \
            -vsync vfr \
            $QUALITY_ARGS \
            "${OUTPUT_DIR}/frame_%05d.${FORMAT}"
        ;;
    *)
        echo "Error: Unknown mode '$MODE'. Use: interval, count, or keyframes" >&2
        exit 1
        ;;
esac

# Count extracted frames
FRAME_COUNT=$(find "$OUTPUT_DIR" -name "frame_*.$FORMAT" -type f | wc -l)
echo ""
echo "Frame extraction complete:"
echo "  Frames extracted: $FRAME_COUNT"
echo "  Output directory: $OUTPUT_DIR"
echo "  Format: $FORMAT"

# List files
for f in "$OUTPUT_DIR"/frame_*."$FORMAT"; do
    if [ -f "$f" ]; then
        SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "unknown")
        echo "  - $(basename "$f") ($SIZE bytes)"
    fi
done
