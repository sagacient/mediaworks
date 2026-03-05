#!/usr/bin/env python3
"""Extract embedded videos from a PPTX file and convert them to audio using ffmpeg.

Usage: ppt_extract_media.py <input_pptx> <output_dir> [output_format] [bitrate]

Arguments:
    input_pptx    - Path to the PPTX file
    output_dir    - Directory to save extracted audio files
    output_format - Audio format: mp3, wav, aac, flac (default: mp3)
    bitrate       - Audio bitrate (default: 192k)
"""

import os
import sys
import subprocess
import zipfile
import shutil
import tempfile


# Known video/audio MIME types and extensions
VIDEO_EXTENSIONS = {'.mp4', '.avi', '.mov', '.wmv', '.m4v', '.mkv', '.webm', '.flv'}
AUDIO_EXTENSIONS = {'.mp3', '.wav', '.m4a', '.aac', '.wma', '.ogg', '.flac'}
MEDIA_EXTENSIONS = VIDEO_EXTENSIONS | AUDIO_EXTENSIONS


def extract_media_from_pptx(pptx_path, output_dir, output_format='mp3', bitrate='192k'):
    """Extract embedded media from PPTX and convert videos to audio."""
    if not os.path.isfile(pptx_path):
        print(f"Error: Input file not found: {pptx_path}", file=sys.stderr)
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)

    # PPTX is a ZIP file — extract media from ppt/media/
    temp_dir = tempfile.mkdtemp()
    extracted_count = 0
    converted_count = 0

    try:
        with zipfile.ZipFile(pptx_path, 'r') as zf:
            media_files = [
                name for name in zf.namelist()
                if name.startswith('ppt/media/')
                and os.path.splitext(name)[1].lower() in MEDIA_EXTENSIONS
            ]

            if not media_files:
                print("No embedded media files found in the presentation.")
                return

            print(f"Found {len(media_files)} embedded media file(s)")
            print()

            for media_path in media_files:
                filename = os.path.basename(media_path)
                ext = os.path.splitext(filename)[1].lower()
                extracted_count += 1

                # Extract to temp directory
                temp_media_path = os.path.join(temp_dir, filename)
                with zf.open(media_path) as src, open(temp_media_path, 'wb') as dst:
                    shutil.copyfileobj(src, dst)

                print(f"  Extracted: {filename}")

                # Determine output filename
                base_name = os.path.splitext(filename)[0]
                output_filename = f"{base_name}.{output_format}"
                output_path = os.path.join(output_dir, output_filename)

                # If it's a video file, convert to audio
                if ext in VIDEO_EXTENSIONS:
                    print(f"  Converting to audio: {output_filename}")
                    try:
                        cmd = [
                            'ffmpeg', '-y', '-hide_banner', '-loglevel', 'warning',
                            '-i', temp_media_path,
                            '-vn', '-b:a', bitrate,
                            output_path
                        ]
                        subprocess.run(cmd, check=True, capture_output=True, text=True)
                        converted_count += 1

                        size = os.path.getsize(output_path)
                        print(f"  Output: {output_filename} ({size} bytes)")
                    except subprocess.CalledProcessError as e:
                        print(f"  Error converting {filename}: {e.stderr}", file=sys.stderr)
                        continue

                # If it's already an audio file, just copy (or convert format)
                elif ext in AUDIO_EXTENSIONS:
                    if ext == f'.{output_format}':
                        # Same format, just copy
                        shutil.copy2(temp_media_path, output_path)
                        converted_count += 1
                        size = os.path.getsize(output_path)
                        print(f"  Copied: {output_filename} ({size} bytes)")
                    else:
                        # Convert audio format
                        print(f"  Converting audio format: {output_filename}")
                        try:
                            cmd = [
                                'ffmpeg', '-y', '-hide_banner', '-loglevel', 'warning',
                                '-i', temp_media_path,
                                '-b:a', bitrate,
                                output_path
                            ]
                            subprocess.run(cmd, check=True, capture_output=True, text=True)
                            converted_count += 1
                            size = os.path.getsize(output_path)
                            print(f"  Output: {output_filename} ({size} bytes)")
                        except subprocess.CalledProcessError as e:
                            print(f"  Error converting {filename}: {e.stderr}", file=sys.stderr)
                            continue

                print()

    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

    print(f"Extraction complete:")
    print(f"  Media files found: {extracted_count}")
    print(f"  Audio files produced: {converted_count}")
    print(f"  Output directory: {output_dir}")
    print(f"  Output format: {output_format}")

    # List output files
    print()
    for f in sorted(os.listdir(output_dir)):
        fpath = os.path.join(output_dir, f)
        if os.path.isfile(fpath):
            size = os.path.getsize(fpath)
            print(f"  - {f} ({size} bytes)")


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: ppt_extract_media.py <input_pptx> <output_dir> [output_format] [bitrate]")
        sys.exit(1)

    pptx_path = sys.argv[1]
    output_dir = sys.argv[2]
    output_format = sys.argv[3] if len(sys.argv) > 3 else 'mp3'
    bitrate = sys.argv[4] if len(sys.argv) > 4 else '192k'

    extract_media_from_pptx(pptx_path, output_dir, output_format, bitrate)
