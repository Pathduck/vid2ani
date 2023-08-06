# video2gif

![sample gif file generated](sample.gif)

A batch script for converting video files to GIF/APNG using FFmpeg on Windows.

## Installation:
* Clone the repo
* Install [FFmpeg](https://www.ffmpeg.org/download.html#build-windows) for Windows.
* Make sure that the path to `ffmpeg.exe` is [configured in your system environment variables control panel](https://www.wikihow.com/Install-FFmpeg-on-Windows) or that you run the `gifconv.bat` file in the same folder as `ffmpeg.exe`.

## Usage:
```
gifconv [input_file] [Arguments]
```
## Options:
```
Arguments:
-------------------------------------------------------------------------------------------------------------
Video to GIF converter v5.1 (C) 2017-2021, MDHEXT & Nabi KaramAliZadeh <nabikaz@gmail.com>
You can download this fork from here: https://github.com/MDHEXT/video2gif
you can download the original release here: https://github.com/NabiKAZ/video2gif
This tool uses ffmpeg, you can download that here: https://www.ffmpeg.org/download.html#build-windows
-------------------------------------------------------------------------------------------------------------
Usage:
gifconv [input_file] [Arguments]
-------------------------------------------------------------------------------------------------------------
Arguments:
-t		: Specifies output filetype - 'gif' or 'apng'. The default is 'gif'.
-o      : Specifies output filename. (will be outputted to the same directory as your input video file.)
          If left empty, this will default to the same filename as your video.
-r      : Specifies scale or size. The amount of pixels this value is set to will be the width of the gif.
          The default is the same scale as the original video.
-f      : Specifies framerate in Hz. The default is 15.
-m      : Specifies one of the 3 modes listed below. The default is diff.
-d      : Specifies which dithering algorithm to be used. The default is Bayer.
-b      : Specifies the Bayer Scale. This can only be used when Bayer Dithering is applied. See more
          information below. (Optional)
-s      : Specifies the start of the gif file in HH:MM:SS.MS format. (Optional)
-e      : Specifies the duration of the gif file in seconds. (Optional)
-c      : Sets the maximum amount of colors useable per palette. (Value up to 256) This option isn't used
          by default.
-k      : Enables error diffusion. (Optional)
-p      : Opens the resulting GIF file in the default Photo Viewer. (Optional)
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
About Bayerscale:
When bayer dithering is selected, the Bayer Scale option defines the scale of the pattern (how much the
crosshatch pattern is visible). A low value means more visible pattern for less banding, and higher value
means less visible pattern at the cost of more banding. The option must be an integer value in the range
[0,5]. The Default is 2. Bayer Scale is optional.
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
When bayer dithering is selected, the Bayer Scale option defines the scale of the pattern (how much the
crosshatch pattern is visible). A low value means more visible pattern for less banding, and higher value
means less visible pattern at the cost of more banding.The option must be an integer value in the range
[0,5]. The Default is 2. Bayer Scale is optional and can only be enabled when using bayer dithering.
```

## Examples:
```
  gifconv sample.mp4
  gifconv sample.mp4 -f 20 -r 450
  gifconv sample.mp4 -s 5:40 -e 5
  gifconv sample.mp4 -o babydance -m 2 -k -b 3
```

## Tips
Special thanks to [this article](http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html).
