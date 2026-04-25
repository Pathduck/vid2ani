# vid2ani

*Video to GIF/APNG/WEBP converter*

![sample webp file](sample.webp)

A batch script for converting video files to GIF/APNG/WEBP using FFmpeg.
Supports scaling, trimming and cropping, preview using 'ffplay' and several options to control palette and dithering.

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
 -o  Output file. Default is the same as input file, sans extension
 -t  Output file type: 'gif' (default), 'apng', 'png', 'webp'
 -r  Resize output width in pixels. Default is original input size
 -l  Enable lossy WebP compression and quality, range 0-100 (default 75)
 -f  Framerate of output, or '-' to use input framerate (default 15)
 -c  Maximum colors usable per palette, range 3-256 (default 256)
 -s  Start time of the animation (HH:MM:SS.MS)
 -e  End time of the animation (HH:MM:SS.MS)
 -x  Crop the input video (out_w:out_h:x:y)
     Note that cropping occurs before output is scaled
 -d  Dithering algorithm to be used (default 0)
 -b  Bayer Scale setting, range 0-5 (default 2)
 -m  Palettegen mode: 1 (diff, default), 2 (single), 3 (full)
 -k  Enables paletteuse error diffusion
 -y  Preview animation using FFplay (part of FFmpeg)
     Useful for testing cropping, but will not use exact start/end time
 -p  Opens the resulting animation in the default image viewer
 -v  Set FFmpeg log level (default: error)

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

## Notes

* Cropping works on the input video before scaling is performed, and passes the parameters
  directly to the [FFmpeg crop filter](https://ffmpeg.org/ffmpeg-filters.html#crop).

* Preview uses FFplay and the script will check for its existence on the PATH.
  FFplay is usually installed along with FFmpeg. The preview is not time-accurate
  and is mostly useful for testing cropping.

* The script will attempt to check for valid inputs, but will fall back to
  FFmpeg's error messages.

* The APNG muxer does not support multiple input palettes, palettegen (-m)
  will fall back to using diff mode if single mode is selected.

* Since FFmpeg can convert between any format, it's also possible to convert
  between for instance GIF to WEBP, although frame rates might be off.

* The script uses ffmpeg, you can download that here: [FFmpeg](https://www.ffmpeg.org/)

* The script was forked from: [MDHEXT/video2gif](https://github.com/MDHEXT/video2gif)
