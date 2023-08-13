# video2gif

*Video to GIF/APNG/WEBP converter v5.5*

![sample gif file generated](sample.gif)

A batch script for converting video files to GIF/APNG/WEBP using FFmpeg on Windows.<br>
(C) 2017-2022, MDHEXT & Nabi KaramAliZadeh <nabikaz@gmail.com>


## Installation
* Clone the repo
* Install [FFmpeg](https://www.ffmpeg.org/download.html#build-windows) for Windows.
* Make sure that the path to `ffmpeg.exe` is 
  [configured in your system environment variables control panel](https://www.wikihow.com/Install-FFmpeg-on-Windows) 
  or that you run the `gifconv.bat` file in the same folder as `ffmpeg.exe`.

## Usage
```
gifconv [input_file] [arguments]
```
## Arguments
```
-t      Specifies output filetype - supported types: gif, png, webp.
        The default is gif.
-o      Specifies output filename.
        Will be output to the same directory as your input video.
        The default is the same as the input video.
-r      Specifies scale or size.
        Width of the animation in pixels.
        The default is the same scale as the original video.
-f      Specifies framerate in frames per second.
        The default is 15.
-m      Specifies one of the 3 modes listed below.
        The default is diff.
-d      Specifies which dithering algorithm to be used.
        The default is 1 (Bayer).
-b      Specifies the Bayer Scale. (Optional)
        This can only be used when Bayer dithering is applied.
        See more information below.
-s      Specifies the start of the animation in HH:MM:SS.MS format.
        (Optional)
-e      Specifies the duration of the animation in seconds.
        (Optional)
-c      Sets the maximum amount of colors useable per palette.
        (Optional value up to 256)
        This option isn't used by default.
-k      Enables error diffusion.
        (Optional)
-p      Opens the resulting animation in your default Photo Viewer.
        (Optional)

Palettegen Modes:
1: diff - only what moves affects the palette
2: single - one palette per frame
3: full - one palette for the whole animation

Dithering Options:
0: No Dithering
1: Bayer
2: Heckbert
3: Floyd Steinberg
4: Sierra2
5: Sierra2_4a
6: sierra3
7: burkes
8: atkinson

About Bayerscale:
When bayer dithering is selected, the Bayer Scale option defines the
scale of the pattern (how much the crosshatch pattern is visible).
A low value means more visible pattern for less banding, a higher value
means less visible pattern at the cost of more banding.
The option must be an integer value in the range [0,5].
The Default is 2. Bayer Scale is optional.
```

## Examples
```
  gifconv sample.mp4
  gifconv sample.mp4 -f 20 -r 450
  gifconv sample.mp4 -s 5:40 -e 5
  gifconv sample.mp4 -o babydance -m 2 -k -b 3
```

## Tips
You can download this fork from here: [MDHEXT/video2gif](https://github.com/MDHEXT/video2gif)<br>
You can download the original release here: [NabiKAZ/video2gif](https://github.com/NabiKAZ/video2gif)<br>
This tool uses ffmpeg, you can download that here: [FFmpeg Windows builds](https://www.ffmpeg.org/download.html#build-windows)<br>
This tool wouldn't be possible without the research listed here: [High quality GIF with FFmpeg](https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html)<br>
