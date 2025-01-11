# vid2ani

*Video to GIF/APNG/WEBP converter*

![sample webp file](sample.webp)

A batch script for converting video files to GIF/APNG/WEBP using FFmpeg.

By *MDHEXT*, *Nabi KaramAliZadeh*, *Pathduck*

Based on the research listed here:
[High quality GIF with FFmpeg](https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html)


## Installation
* Clone the repo.
* Install [FFmpeg](https://www.ffmpeg.org/).
* For Windows make sure that the path to `ffmpeg.exe` is
  [configured in your system environment variables control panel](https://www.wikihow.com/Install-FFmpeg-on-Windows).

## Usage
```
vid2ani [input_file] [arguments]
```
## Arguments
```
  -o  Output file. Default is the same as input file, sans extension.
  -t  Output file type. Valid: 'gif' (default), 'apng', 'png', 'webp'.
  -r  Scale or size. Width of the animation in pixels.
  -l  Enable lossy WebP compression and quality. Range 0-100, default 75.
  -f  Framerate in frames per seconds, default 15.
  -s  Start time of the animation (HH:MM:SS.MS).
  -e  End time of the animation (HH:MM:SS.MS).
  -d  Dithering algorithm to be used, default 0.
  -b  Bayer Scale setting. Range 0-5, default 2.
  -m  Palettegen mode: 1 (diff), 2 (single), 3 (full), default 1.
  -c  Maximum colors usable per palette. Range 3-256 (default).
  -k  Enables paletteuse error diffusion.
  -p  Opens the resulting animation in the default image viewer.
  -v  Set FFmpeg log level (default: error).

Dithering Algorithms:
  0: None
  1: Bayer
  2: Heckbert
  3: Floyd Steinberg
  4: Sierra2
  5: Sierra2_4a
  6: Sierra3
  7: Burkes
  8: Atkinson


Palettegen Modes:
  1: diff - only what moves affects the palette
  2: single - one palette per frame
  3: full - one palette for the whole animation

About Bayerscale:
When bayer dithering is selected, the Bayer Scale option defines the
scale of the pattern (how much the crosshatch pattern is visible).
A low value means more visible pattern for less banding, a higher value
means less visible pattern at the cost of more banding.
```

## Examples
```
  vid2ani sample.mp4
  vid2ani sample.mp4 -t png
  vid2ani sample.mp4 -t webp -l 50
  vid2ani sample.mp4 -f 20 -r 450
  vid2ani sample.mp4 -s 5:40 -e 5:45
  vid2ani sample.mp4 -o babydance -m 2 -k -d 1 -b 3
```

## Notes
* The script will attempt to check for valid inputs, but will fall back to FFmpeg's error messages.
* The APNG muxer does not support multiple input palettes, palettegen (-m) will fall
back to using diff mode if single mode is selected.
* Since FFmpeg can convert between any format, it's also possible to convert
between for instance GIF to WEBP, although frame rates might be off.
* The script uses ffmpeg, you can download that here: [FFmpeg](https://www.ffmpeg.org/)
* The script was forked from: [MDHEXT/video2gif](https://github.com/MDHEXT/video2gif)
