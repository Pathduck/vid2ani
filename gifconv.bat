@ECHO OFF
REM  By: MDHEXT, Nabi KaramAliZadeh <nabikaz@gmail.com>
REM Description: Video to GIF converter
REM Version: 4.0b
REM Url: https://github.com/MDHEXT/video2gif, forked from https://github.com/NabiKAZ/video2gif
REM License: The MIT License (MIT)

SETLOCAL ENABLEDELAYEDEXPANSION
SET input=%~1
SET vid=%~dpnx1
SET output=%~dpn1.gif
SET FILEPATH=%~dp1

SET "scale="
SET "fps="
SET "mode="
SET "dither="
SET "bayerscale="
SET "start_time="
SET "duration="
SET "colormax="

SET WD=%TEMP%\GIFCONV
SET palette=%WD%\template
GOTO :help_check_1

:help_message
ECHO -------------------------------------------------------------------------------------------------------------
ECHO Video to GIF converter v4.0b ^(C^) 2017-2021, MDHEXT ^&^ Nabi KaramAliZadeh ^<nabikaz@gmail.com^>
ECHO You can download this fork from here: https://github.com/MDHEXT/video2gif
ECHO you can download the original release here: https://github.com/NabiKAZ/video2gif
ECHO This tool uses ffmpeg, you can download that here: https://www.ffmpeg.org/download.html#build-windows
ECHO -------------------------------------------------------------------------------------------------------------
ECHO Usage:
ECHO gifconv [input_file] [Arguments]
ECHO -------------------------------------------------------------------------------------------------------------
ECHO Arguments:
ECHO	-o	: Specifies output filename. (will be outputted to the same directory as your input video file.)
ECHO		  If left empty, this will default to the same filename as your video. (Usage: -o image.gif)
ECHO	-r	: Specifies scale or size. The amount of pixels this value is set to will be the width of the gif.
ECHO		  The default is the same scale as the original video.
ECHO	-f	: Specifies framerate in Hz. The default is 15.
ECHO	-m	: Specifies one of the 3 modes listed below. The default is diff.
ECHO	-d	: Specifies which dithering algorithm to be used. The default is Bayer Dithering.
ECHO	-b	: Specifies the Bayer Scale. This can only be used when Bayer Dithering is applied.
ECHO		  See more information below.
ECHO	-s	: Specifies the start of the gif file in HH:MM:SS.MS format.
ECHO	-e	: Specifies the duration of the gif file in seconds.
ECHO	-c	: Sets the maximum amount of colors useable per palette. (Value up to 256) This option is disabled
ECHO		  by default.
ECHO -------------------------------------------------------------------------------------------------------------
ECHO Palettegen Modes:
ECHO 1: diff - only what moves affects the palette
ECHO 2: single - one palette per frame
ECHO 3: full - one palette for the whole gif
ECHO -------------------------------------------------------------------------------------------------------------
ECHO Dithering Options:
ECHO 1: Bayer
ECHO 2: Heckbert
ECHO 3: Floyd Steinberg
ECHO 4: Sierra2
ECHO 5: Sierra2_4a
ECHO 6: No Dithering
ECHO -------------------------------------------------------------------------------------------------------------
ECHO When bayer dithering is selected, the Bayer Scale option defines the scale of the pattern (how much the 
ECHO crosshatch pattern is visible). A low value means more visible pattern for less banding, and higher value
ECHO means less visible pattern at the cost of more banding.The option must be an integer value in the range
ECHO [0,5]. The Default is 2. Bayer Scale is optional and can only be enabled when using bayer dithering.
GOTO :EOF

:safchek
IF DEFINED bayerscale (
	IF !bayerscale! GTR 5 (
		ECHO Not a valid bayerscale value
		GOTO :EOF
		)
	IF !bayerscale! LEQ 5 (
		IF %dither% EQU 1 GOTO :script_start
		IF %dither% NEQ 1 (
			ECHO This setting only works with bayer dithering
			GOTO :EOF
		)
	)
)
GOTO :script_start

:varin
IF NOT "%~1" =="" (
	IF "%~1" =="-r" SET "scale=%~2" & SHIFT
	IF "%~1" =="-f" SET "fps=%~2" & SHIFT
	IF "%~1" =="-m" SET "mode=%~2" & SHIFT
	IF "%~1" =="-d" SET "dither=%~2" & SHIFT
	IF "%~1" =="-b" SET "bayerscale=%~2" & SHIFT
	IF "%~1" =="-o" SET "output=%FILEPATH%%~2" & SHIFT
	IF "%~1" =="-s" SET "start_time=%~2" & SHIFT
	IF "%~1" =="-e" SET "duration=%~2" & SHIFT
	IF "%~1" =="-c" SET "colormax=%~2" & SHIFT
	SHIFT
	GOTO :varin
)
GOTO :help_check_2

:help_check_1
IF "%input%" == "" GOTO :help_message
IF "%input%" == "help" GOTO :help_message
IF "%input%" == "h" GOTO :help_message
GOTO :varin

:help_check_2
IF NOT DEFINED scale SET "scale=-1"
IF NOT DEFINED fps SET fps=15
IF NOT DEFINED mode SET mode=1
IF NOT DEFINED dither SET dither=1
GOTO :safchek

:script_start
ECHO Creating Working Directory...
MD "%WD%"

:palettegen
ECHO Generating Palette...
IF DEFINED start_time (
	IF DEFINED duration SET "trim=-ss %start_time% -t %duration%"
	IF NOT DEFINED duration (
		ECHO Please input a duration
		GOTO :EOF
	)
)
SET frames=%palette%
SET filters=fps=%fps%,scale=%scale%:-1:flags=lanczos

IF %mode% EQU 1 SET encode=palettegen=stats_mode=diff
IF %mode% EQU 2 SET encode=palettegen=stats_mode=single & SET frames=%palette%_%%05d
IF %mode% EQU 3 SET encode=palettegen
IF DEFINED colormax SET "mcol=:max_colors=%colormax%"
ffmpeg -v warning %trim% -i "%vid%" -vf "%filters%,%encode%%mcol%" -y "%frames%.png"
IF NOT EXIST "%palette%_00001.png" (
	IF NOT EXIST "%palette%.png" (
		ECHO Failed to generate palette file
		GOTO :cleanup
		)
)
ECHO Encoding Gif file...
IF %mode% EQU 1 SET decode=paletteuse=diff_mode=rectangle
IF %mode% EQU 2 SET decode=paletteuse=new=1 & SET frames=%palette%_%%05d
IF %mode% EQU 3 SET decode=paletteuse=diff_mode=rectangle
IF %dither% EQU 1 SET ditherenc=:dither=bayer
IF %dither% EQU 2 SET ditherenc=:dither=heckbert
IF %dither% EQU 3 SET ditherenc=:dither=floyd_steinberg
IF %dither% EQU 4 SET ditherenc=:sierra2
IF %dither% EQU 5 SET ditherenc=:sierra2_4a
IF %dither% EQU 6 SET "ditherenc="
IF NOT DEFINED bayerscale SET "bayer="
IF DEFINED bayerscale SET bayer=:bayer_scale=%bayerscale%

ffmpeg -v warning %trim% -i "%vid%" -thread_queue_size 512 -i "%frames%.png" -lavfi "%filters% [x]; [x][1:v] %decode%%ditherenc%%bayer%" -y "%output%"
IF NOT EXIST "%output%" (
	ECHO Failed to generate gif file
	GOTO :cleanup
)
:cleanup
ECHO Deleting Temporary files...
RMDIR /S /Q "%WD%"
ECHO Done!