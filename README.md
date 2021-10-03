# video2gif

![sample gif file generated](sample.gif)

A batch script for converting video files to GIF using FFmpeg on Windows.

## Installation
* Clone the repo
* Install [FFmpeg](https://www.ffmpeg.org/download.html#build-windows) for Windows.
* Make sure that the path to `ffmpeg.exe` is configured in your system environment variables control panel or that you run the `gifenc.bat` file in the same folder as `ffmpeg.exe`.

## Usage
```
gifenc [input_file] [width_in_pixels] [framerate_in_Hz] [palettegen_mode] [Dithering_Algorithm] [Bayer_Scale]
```
Always make sure the current directory is the same as the one the video file is in, otherwise the conversion will fail.
## Options:
```
-------------------------------------------------------------------------------------------------------------
Palettegen Modes:
1: diff - only what moves affects the palette
2: single - one palette per frame
3: full - one palette for the whole gif
-------------------------------------------------------------------------------------------------------------
Dithering Options:
1: Bayer
2: Heckbert
3: Floyd Steinberg
4: Sierra2
5: Sierra2_4a
6: No Dithering
-------------------------------------------------------------------------------------------------------------
When bayer dithering is selected, the Bayer Scale option defines the scale of the pattern (how much the crosshatch 
pattern is visible). A low value means more visible pattern for less banding, and higher value means less 
visible pattern at the cost of more banding.The option must be an integer value in the range [0,5]. 
The Default is 2.
Bayer Scale is optional and can only be enabled when using bayer dithering
```

## Examples:
```
  gifenc sample.mp4 300 15 1 1
  gifenc sample.mp4 600 10 2 3
  gifenc sample.mp4 350 13 3 1

```

## Tips
Special thanks to [this article](http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html).
