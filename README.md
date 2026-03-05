# 🎬 MediaWorks

Comprehensive Docker image with ffmpeg, LibreOffice, and python-pptx for media processing in MCP (Model Context Protocol) servers.

## Quick Start

```bash
docker pull sagacient/mediaworks:latest
```

## 📦 Included Software

### Audio & Video Processing
| Package | Description |
|---------|-------------|
| ffmpeg | Full audio/video transcoding, extraction, conversion, muxing |
| ffprobe | Media file analysis and metadata extraction |

### Presentation Processing
| Package | Description |
|---------|-------------|
| LibreOffice Impress | PPT/PPTX slide rendering (headless mode) |
| python-pptx | PowerPoint file parsing and media extraction |

### Image Processing
| Package | Description |
|---------|-------------|
| Pillow | Image manipulation and format conversion |

### System Fonts
| Package | Description |
|---------|-------------|
| fonts-liberation | Liberation font family (metrics-compatible with Arial, Times, Courier) |
| fonts-dejavu-core | DejaVu font family |
| fonts-noto-core | Google Noto fonts (broad Unicode coverage) |

## 📜 Helper Scripts

Pre-installed scripts in `/scripts/` for common operations:

| Script | Description |
|--------|-------------|
| `extract_audio.sh` | Extract audio from video (full or clipped, configurable format/bitrate) |
| `extract_frames.sh` | Sample frames from video (by interval, count, or keyframes) |
| `images_to_video.sh` | Create video from image sequence with optional SRT subtitles |
| `ppt_slides_to_images.sh` | Export PPT/PPTX slides as images via LibreOffice headless |
| `ppt_extract_media.py` | Extract embedded video/audio from PPTX, convert to audio |

## ✨ Key Features

- 🎵 **Audio Extraction** — Extract audio from any video format, with clipping support
- 🖼️ **Frame Sampling** — Extract frames at intervals, by count, or keyframes only
- 🎥 **Video Creation** — Build videos from image sequences with subtitle overlay
- 📊 **Slide Export** — Convert PPT/PPTX slides to high-quality images
- 🔊 **Presentation Audio** — Extract embedded media from PPTX and convert to audio
- 🔒 **Security Hardened** — Non-root user, minimal base image

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest stable build from main branch |
| `vX.Y.Z` | Specific version release |
| `YYYYMMDD` | Daily build with date |
| `<sha>` | Specific commit build |

## Platforms

- `linux/amd64` (Intel/AMD)
- `linux/arm64` (Apple Silicon, ARM servers)

## Usage Examples

### Extract Audio from Video
```bash
docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks /scripts/extract_audio.sh \
    /data/video.mp4 /output/audio.mp3
```

### Extract Audio Clip (30s to 1m30s)
```bash
docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks /scripts/extract_audio.sh \
    /data/video.mp4 /output/clip.mp3 00:00:30 00:01:30
```

### Sample Frames (every 10 seconds)
```bash
docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks /scripts/extract_frames.sh \
    /data/video.mp4 /output interval 10 jpg 85
```

### Extract Keyframes Only
```bash
docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks /scripts/extract_frames.sh \
    /data/video.mp4 /output keyframes
```

### Export PPT Slides as Images
```bash
docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks /scripts/ppt_slides_to_images.sh \
    /data/presentation.pptx /output png
```

### Extract Audio from PPTX Embedded Videos
```bash
docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks python3 /scripts/ppt_extract_media.py \
    /data/presentation.pptx /output mp3 192k
```

### Create Video from Images with Subtitles
```bash
# Create image list file
ls /data/frames/*.jpg > /tmp/images.txt

docker run --rm -v $(pwd):/data:ro -v $(pwd)/output:/output \
    sagacient/mediaworks /scripts/images_to_video.sh \
    /tmp/images.txt /output/video.mp4 24 3 1920x1080 /data/subtitles.srt
```

## 🔒 Security

- Runs as non-root user (`mediaworks`, UID 1000)
- No network access by default (when used with MCP server)
- Ubuntu 24.04 LTS base image
- System dependencies kept to minimum necessary
- Regular updates with latest stable package versions

## 🛠️ System Dependencies

Pre-installed system packages:
- **FFmpeg** — Full audio/video processing suite
- **LibreOffice Impress** — Presentation rendering engine (headless)
- **Python 3** — Runtime for python-pptx scripts
- **Liberation/DejaVu/Noto fonts** — Font coverage for slide rendering

## Building Locally

```bash
docker build -t mediaworks:latest .
```

## Use Cases

- 🎵 Audio extraction from video files
- 🖼️ Video frame sampling and thumbnailing
- 🎥 Slideshow video creation with subtitles
- 📊 Presentation slide export as images
- 🔊 Embedded media extraction from PowerPoint
- 🎬 Media format conversion pipelines

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

[Mozilla Public License 2.0 (MPL-2.0)](LICENSE)
