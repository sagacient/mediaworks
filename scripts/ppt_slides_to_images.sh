#!/bin/bash
# Export PPT/PPTX slides as images using LibreOffice headless.
#
# Usage: ppt_slides_to_images.sh <input_pptx> <output_dir> [format] [slides]
#
# Arguments:
#   input_pptx - Path to the PPT/PPTX file
#   output_dir - Directory to save slide images
#   format     - Output format: png or jpg (default: png)
#   slides     - Comma-separated slide numbers to export (default: all)
#                Example: "1,3,5" exports only slides 1, 3, and 5

set -euo pipefail

INPUT="$1"
OUTPUT_DIR="$2"
FORMAT="${3:-png}"
SLIDES="${4:-}"

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Exporting slides from: $(basename "$INPUT")"
echo "Output format: $FORMAT"
echo ""

# Use a temporary directory for LibreOffice export
TEMP_EXPORT_DIR=$(mktemp -d)

# LibreOffice exports to PDF first, then we convert to images
# Step 1: Convert PPTX to PDF using LibreOffice headless
echo "Converting presentation to PDF..."
libreoffice --headless --convert-to pdf --outdir "$TEMP_EXPORT_DIR" "$INPUT" 2>/dev/null

# Find the PDF file
PDF_FILE=$(find "$TEMP_EXPORT_DIR" -name "*.pdf" -type f | head -1)

if [ ! -f "$PDF_FILE" ]; then
    echo "Error: LibreOffice conversion failed" >&2
    rm -rf "$TEMP_EXPORT_DIR"
    exit 1
fi

# Step 2: Convert PDF pages to images using ffmpeg
# Get page count
PAGE_COUNT=$(ffprobe -v quiet -select_streams v -show_entries stream=nb_frames -of csv=p=0 "$PDF_FILE" 2>/dev/null || echo "0")

# If ffprobe can't get page count, use Python to count
if [ "$PAGE_COUNT" = "0" ] || [ -z "$PAGE_COUNT" ]; then
    PAGE_COUNT=$(python3 -c "
import subprocess
result = subprocess.run(['ffprobe', '-v', 'quiet', '-count_frames', '-select_streams', 'v:0', 
                         '-show_entries', 'stream=nb_read_frames', '-of', 'csv=p=0', '$PDF_FILE'],
                        capture_output=True, text=True)
print(result.stdout.strip() if result.stdout.strip() else '0')
" 2>/dev/null || echo "0")
fi

# Alternative: use pdftoppm if available for better quality
if command -v pdftoppm &>/dev/null; then
    echo "Using pdftoppm for image conversion..."
    if [ "$FORMAT" = "png" ]; then
        pdftoppm -png -r 300 "$PDF_FILE" "${TEMP_EXPORT_DIR}/slide"
    else
        pdftoppm -jpeg -jpegopt quality=95 -r 300 "$PDF_FILE" "${TEMP_EXPORT_DIR}/slide"
    fi
else
    # Fallback: use ffmpeg to convert PDF to images
    echo "Using ffmpeg for image conversion..."
    ffmpeg -y -hide_banner -loglevel warning \
        -i "$PDF_FILE" \
        -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:white" \
        "${TEMP_EXPORT_DIR}/slide-%03d.${FORMAT}"
fi

# Move/filter slides to output directory
SLIDE_NUM=0
EXPORTED=0

for img in "$TEMP_EXPORT_DIR"/slide*."$FORMAT" "$TEMP_EXPORT_DIR"/slide-*."$FORMAT"; do
    [ ! -f "$img" ] && continue
    SLIDE_NUM=$((SLIDE_NUM + 1))
    
    # Filter by slide numbers if specified
    if [ -n "$SLIDES" ]; then
        if ! echo ",$SLIDES," | grep -q ",$SLIDE_NUM,"; then
            continue
        fi
    fi
    
    cp "$img" "${OUTPUT_DIR}/slide_$(printf '%03d' $SLIDE_NUM).${FORMAT}"
    EXPORTED=$((EXPORTED + 1))
done

# Clean up
rm -rf "$TEMP_EXPORT_DIR"

echo ""
echo "Slide export complete:"
echo "  Total slides: $SLIDE_NUM"
echo "  Exported: $EXPORTED"
echo "  Format: $FORMAT"
echo "  Output directory: $OUTPUT_DIR"
echo ""

# List exported files
for f in "$OUTPUT_DIR"/slide_*."$FORMAT"; do
    if [ -f "$f" ]; then
        SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "unknown")
        echo "  - $(basename "$f") ($SIZE bytes)"
    fi
done
