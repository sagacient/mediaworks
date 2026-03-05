#!/bin/bash
# Create a video from a sequence of images, with optional subtitles overlay.
#
# Usage: images_to_video.sh <image_list_file> <output_video> [fps] [duration_per_image] [resolution] [subtitle_file]
#
# Arguments:
#   image_list_file    - Path to a text file listing image paths (one per line, in order)
#   output_video       - Path to the output video file
#   fps                - Frames per second (default: 24)
#   duration_per_image - Seconds each image is shown (default: 3)
#   resolution         - Output resolution WxH (default: 1920x1080)
#   subtitle_file      - Optional path to an SRT subtitle file

set -euo pipefail

IMAGE_LIST="$1"
OUTPUT="$2"
FPS="${3:-24}"
DURATION_PER_IMAGE="${4:-3}"
RESOLUTION="${5:-1920x1080}"
SUBTITLE_FILE="${6:-}"

if [ ! -f "$IMAGE_LIST" ]; then
    echo "Error: Image list file not found: $IMAGE_LIST" >&2
    exit 1
fi

# Parse resolution
WIDTH=$(echo "$RESOLUTION" | cut -dx -f1)
HEIGHT=$(echo "$RESOLUTION" | cut -dx -f2)

# Count images
IMAGE_COUNT=$(wc -l < "$IMAGE_LIST")
if [ "$IMAGE_COUNT" -eq 0 ]; then
    echo "Error: Image list is empty" >&2
    exit 1
fi

echo "Creating video from $IMAGE_COUNT images"
echo "Output: $(basename "$OUTPUT")"
echo "FPS: $FPS"
echo "Duration per image: ${DURATION_PER_IMAGE}s"
echo "Resolution: ${WIDTH}x${HEIGHT}"
[ -n "$SUBTITLE_FILE" ] && echo "Subtitles: $(basename "$SUBTITLE_FILE")"
echo ""

# Create a concat demuxer file for ffmpeg
CONCAT_FILE="/tmp/concat_list.txt"
> "$CONCAT_FILE"

while IFS= read -r img_path; do
    # Skip empty lines
    [ -z "$img_path" ] && continue
    
    if [ ! -f "$img_path" ]; then
        echo "Warning: Image not found, skipping: $img_path" >&2
        continue
    fi
    
    echo "file '$img_path'" >> "$CONCAT_FILE"
    echo "duration $DURATION_PER_IMAGE" >> "$CONCAT_FILE"
done < "$IMAGE_LIST"

# Add last image again (ffmpeg concat demuxer quirk)
LAST_IMAGE=$(tail -n1 "$IMAGE_LIST")
if [ -n "$LAST_IMAGE" ] && [ -f "$LAST_IMAGE" ]; then
    echo "file '$LAST_IMAGE'" >> "$CONCAT_FILE"
fi

# Build ffmpeg command
FFMPEG_ARGS=(-y -hide_banner -loglevel warning)
FFMPEG_ARGS+=(-f concat -safe 0 -i "$CONCAT_FILE")

# Video filter: scale + pad to target resolution
VF="scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease,pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2:black"

# Add subtitles if provided
if [ -n "$SUBTITLE_FILE" ] && [ -f "$SUBTITLE_FILE" ]; then
    VF="${VF},subtitles='${SUBTITLE_FILE}'"
fi

FFMPEG_ARGS+=(-vf "$VF")
FFMPEG_ARGS+=(-r "$FPS")
FFMPEG_ARGS+=(-c:v libx264 -pix_fmt yuv420p -preset medium -crf 23)
FFMPEG_ARGS+=("$OUTPUT")

ffmpeg "${FFMPEG_ARGS[@]}"

# Clean up
rm -f "$CONCAT_FILE"

# Report output
if [ -f "$OUTPUT" ]; then
    SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null || stat -f%z "$OUTPUT" 2>/dev/null || echo "unknown")
    DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT" 2>/dev/null || echo "unknown")
    echo ""
    echo "Video creation complete:"
    echo "  File: $(basename "$OUTPUT")"
    echo "  Size: $SIZE bytes"
    echo "  Duration: ${DURATION}s"
    echo "  Resolution: ${WIDTH}x${HEIGHT}"
    echo "  Images used: $IMAGE_COUNT"
else
    echo "Error: Output file was not created" >&2
    exit 1
fi
