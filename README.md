# video2gif

![sample gif file generated](sample.gif)

A batch script for converting video files to GIF using FFmpeg on Windows.

## Installation
* Clone the repo
* Install [FFmpeg](https://www.ffmpeg.org/download.html#build-windows) for Windows.
* Make sure that the path to `ffmpeg.exe` is configured in your system environment variables control panel or that you run the `gifconv.bat` file in the same folder as `ffmpeg.exe`.

## Usage
```
gifconv [input_file] [Arguments]
```
## Options:
```
Arguments:
 -o	: Specifies output filename. (will be outputted to the same directory as your input video file.)
		  If left empty, this will default to the same filename as your video. (Usage: -o image.gif)
 -r	: Specifies scale or size. The amount of pixels this value is set to will be the width of the gif.
		  The default is the same scale as the original video.
 -f	: Specifies framerate in Hz. THe default is 15.
 -m	: Specifies one of the 3 modes listed below. The default is diff.
 -d	: Specifies which dithering algorithm to be used. The default is Bayer Dithering.
 -b	: Specifies the Bayer Scale. This can only be used when Bayer Dithering is applied.
  	  See more information below.
 -s	: Specifies the start of the gif file in M:S format.
 -e	: Specifies the duration of the gif file in seconds.
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
  gifenc sample.mp4
  gifenc sample.mp4 -f 20 -r 450
  gifenc sample.mp4 -s 5:40 -e 5

```

## Tips
Special thanks to [this article](http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html).
