@ECHO OFF
:: Description: Video to GIF/APNG/WEBP converter
:: By: MDHEXT, Nabi KaramAliZadeh, Pathduck
:: Version: 6.0
:: Url: https://github.com/Pathduck/vid2ani/ forked from https://github.com/MDHEXT/video2gif
:: What this script is based on: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
:: License: GNU General Public License v3.0 (GPLv3)

:: Enable delayed variable expension
SETLOCAL ENABLEDELAYEDEXPANSION

:: Colors
SET OFF=[0m
SET GREEN=[32m
SET YELLOW=[33m
SET RED=[91m
SET CYAN=[96m

:: Storing Paths
SET input="%~1"
SET vid="%~dpnx1"
SET output=%~dpn1

:: Setting the path to the Working Directory
SET WD=%TEMP%\VID2ANI

:: Checking for blank input or help commands
IF %input% == "" GOTO :help_message
IF %input% == "-?" GOTO :help_message
IF %input% == "/?" GOTO :help_message
IF %input% == "help" GOTO :help_message
IF %input% == "--help" GOTO :help_message

:: Clearing all variables
SET "scale="
SET "fps="
SET "mode="
SET "dither="
SET "bayerscale="
SET "filetype="
SET "start_time="
SET "end_time="
SET "webp_lossy="
SET "colormax="
SET "version="
SET "build="
SET "loglevel="

GOTO :varin

:varin
:: Using SHIFT command to go through the input and storing each setting into its own variable
IF NOT "%~1" =="" (
	IF "%~1" =="-r" SET "scale=%~2" & SHIFT
	IF "%~1" =="-f" SET "fps=%~2" & SHIFT
	IF "%~1" =="-m" SET "mode=%~2" & SHIFT
	IF "%~1" =="-d" SET "dither=%~2" & SHIFT
	IF "%~1" =="-b" SET "bayerscale=%~2" & SHIFT
	IF "%~1" =="-t" SET "filetype=%~2" & SHIFT
	IF "%~1" =="-o" SET "output=%~dpn2" & SHIFT
	IF "%~1" =="-s" SET "start_time=%~2" & SHIFT
	IF "%~1" =="-e" SET "end_time=%~2" & SHIFT
	IF "%~1" =="-c" SET "colormax=%~2" & SHIFT
	IF "%~1" =="-l" SET "webp_lossy=%~2" & SHIFT
	IF "%~1" =="-v" SET "loglevel=%~2" & SHIFT
	IF "%~1" =="-k" SET "errorswitch=1"
	IF "%~1" =="-p" SET "picswitch=1"
	SHIFT & GOTO :varin
)
GOTO :help_check_2

:help_check_2
:: Noob proofing the script to prevent it from breaking should critical settings not be defined
IF NOT DEFINED scale SET "scale=-1"
IF NOT DEFINED fps SET fps=15
IF NOT DEFINED mode SET mode=1
IF NOT DEFINED dither SET dither=0
IF NOT DEFINED filetype SET "filetype=gif"
IF NOT DEFINED loglevel SET "loglevel=error"

GOTO :safchek

:safchek
:: Setting a clear range of acceptable setting values and noob proofing bayerscale

:: Output file type
echo %filetype% | findstr /r "\<gif\> \<png\> \<apng\> \<webp\>" >nul
IF %errorlevel% NEQ 0 (
	ECHO %RED%Not a valid file type: %filetype%%OFF%
	GOTO :EOF
)
IF "%filetype%"=="png" SET filetype=apng
IF "%filetype%"=="apng" SET output=%output%.png
IF "%filetype%"=="webp" SET output=%output%.webp
IF "%filetype%"=="gif" SET output=%output%.gif

:: Palettegen
IF %mode% GTR 3 (
	ECHO %RED%Not a valid palettegen mode%OFF%
	GOTO :EOF
) ELSE IF %mode% LSS 1 (
	ECHO %RED%Not a valid palettegen mode%OFF%
	GOTO :EOF
)
:: Dithering
IF %dither% GTR 8 (
	ECHO %RED%Not a valid dither algorithm%OFF%
	GOTO :EOF
) ELSE IF %dither% LSS 0 (
	ECHO %RED%Not a valid dither algorithm%OFF%
	GOTO :EOF
)

::  Bayerscale
IF DEFINED bayerscale (
	IF !bayerscale! GTR 5 (
		ECHO %RED%Not a valid bayerscale value%OFF%
		GOTO :EOF
	) ELSE IF !bayerscale! LSS 0 (
		ECHO %RED%Not a valid bayerscale value%OFF%
		GOTO :EOF
	)
	IF !bayerscale! LEQ 5 (
		IF %dither% NEQ 1 (
			ECHO %RED%This setting only works with bayer dithering%OFF%
			GOTO :EOF
		)
	)
)

:: Lossy WEBP
IF DEFINED webp_lossy (
	IF NOT "%filetype%" == "webp" (
		ECHO %RED%Lossy is only valid for filetype webp%OFF%
		GOTO :EOF
	) ELSE IF !webp_lossy! GTR 100 (
		ECHO %RED%Not a valid lossy quality value%OFF%
		GOTO :EOF
	) ELSE IF !webp_lossy! LSS 0 (
		ECHO %RED%Not a valid lossy quality value%OFF%
		GOTO :EOF
	)
)

:: Noob Proofing clipping
IF DEFINED start_time (
	IF DEFINED end_time SET "trim=-ss !start_time! -to !end_time!"
	IF NOT DEFINED end_time (
		ECHO %RED%Please input the end time%OFF%
		GOTO :EOF
	)
)

IF NOT DEFINED start_time (
	IF DEFINED end_time (
		ECHO %RED%Please input the start time%OFF%
		GOTO :EOF
	)
)
GOTO :script_start

:script_start
:: Storing FFmpeg version string
FOR /F "delims=" %%a in ('ffmpeg -version') DO (
	IF NOT DEFINED version (
		SET "version=%%a"
	) ELSE IF NOT DEFINED build (
		SET "build=%%a"
	)
)

:: Displaying FFmpeg version string and creating the working directory
ECHO %YELLOW%%version%%OFF%
ECHO %YELLOW%%build%%OFF%
ECHO %GREEN%Output file:%OFF% %output%
ECHO %GREEN%Creating working directory...%OFF%
MD "%WD%"

:palettegen
:: Putting together command to generate palette
SET palette=%WD%\palette
SET frames=%palette%_%%05d
SET filters=fps=%fps%,scale=%scale%:-1:flags=lanczos

:: Palettegen mode
IF %mode% EQU 1 SET encode=palettegen=stats_mode=diff
IF %mode% EQU 2 SET encode="palettegen=stats_mode=single"
IF %mode% EQU 3 SET encode=palettegen

:: Max colors
IF DEFINED colormax (
	IF %mode% LEQ 2 SET "mcol=:max_colors=%colormax%"
	IF %mode% EQU 3 SET "mcol==max_colors=%colormax%"
)

:: Executing command to generate palette
ECHO %GREEN%Generating palette...%OFF%
ffmpeg -v %loglevel% %trim% -i %vid% -vf "%filters%,%encode%%mcol%" -y "%frames%.png"

:: Checking if the palette file is in the Working Directory, if not cleaning up
IF NOT EXIST "%palette%_00001.png" (
	IF NOT EXIST "%palette%.png" (
		ECHO %RED%Failed to generate palette file%OFF%
		GOTO :cleanup
	)
)

:: Setting variables to put the encode command together
:: Checking for Error Diffusion if using Bayer Scale and adjusting the command accordingly
IF %mode% EQU 1 SET decode=paletteuse
IF %mode% EQU 2 SET "decode=paletteuse=new=1"
IF %mode% EQU 3 SET decode=paletteuse

:: Error diffusion
IF DEFINED errorswitch (
	IF %mode% EQU 1 SET "errordiff==diff_mode=rectangle"
	IF %mode% EQU 2 SET "errordiff=:diff_mode=rectangle"
	IF %mode% EQU 3 SET "errordiff==diff_mode=rectangle"
)

:: WEBP pixel format and lossy quality
IF "%filetype%" == "webp" (
	IF DEFINED webp_lossy (
		SET "webp_lossy=-lossless 0 -pix_fmt yuva420p -quality %webp_lossy%"
	) ELSE SET "webp_lossy=-lossless 1"
)

:: Dither algorithm
IF %dither% EQU 0 SET ditheralg=none
IF %dither% EQU 1 SET ditheralg=bayer
IF %dither% EQU 2 SET ditheralg=heckbert
IF %dither% EQU 3 SET ditheralg=floyd_steinberg
IF %dither% EQU 4 SET ditheralg=sierra2
IF %dither% EQU 5 SET ditheralg=sierra2_4a
IF %dither% EQU 6 SET ditheralg=sierra3
IF %dither% EQU 7 SET ditheralg=burkes
IF %dither% EQU 8 SET ditheralg=atkinson

IF NOT %mode% EQU 2 (
	IF DEFINED errorswitch SET ditherenc=:dither=!ditheralg!
	IF NOT DEFINED errorswitch SET ditherenc==dither=!ditheralg!
) ELSE SET ditherenc=:dither=!ditheralg!

:: Checking for Bayer Scale and adjusting command
IF NOT DEFINED bayerscale SET "bayer="
IF DEFINED bayerscale SET bayer=:bayer_scale=%bayerscale%

:: Executing the encoding command
ECHO %GREEN%Encoding animation...%OFF%
ffmpeg -v %loglevel% %trim% -i %vid% -thread_queue_size 512 -i "%frames%.png" -lavfi "%filters% [x]; [x][1:v] %decode%%errordiff%%ditherenc%%bayer%" -f %filetype% %webp_lossy% -loop 0 -plays 0 -y "%output%"

:: Checking if file was created and cleaning up if not
IF NOT EXIST "%output%" (
	ECHO %RED%Failed to generate animation%OFF%
	GOTO :cleanup
)

:: Starting default Photo Viewer
IF DEFINED picswitch START "" "%output%"

:cleanup
:: Cleaning up
ECHO %GREEN%Deleting temporary files...%OFF%
RMDIR /S /Q "%WD%"
ECHO %YELLOW%Done.%OFF%
ENDLOCAL
GOTO :EOF

:help_message
:: Print usage message
ECHO:
ECHO %GREEN%Video to GIF/APNG/WEBP converter v6.0%OFF%
ECHO %CYAN%By MDHEXT, Nabi KaramAliZadeh, Pathduck%OFF%
ECHO:
ECHO You can download this fork from here:
ECHO %CYAN%https://github.com/Pathduck/vid2ani/%OFF%
ECHO You can download the original release here:
ECHO %CYAN%https://github.com/NabiKAZ/video2gif%OFF%
ECHO This tool uses ffmpeg, you can download that here:
ECHO %CYAN%https://www.ffmpeg.org/download.html%OFF%
ECHO This tool wouldn't be possible without the research listed here:
ECHO %CYAN%https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html%OFF%
ECHO:
ECHO %GREEN%Usage:%OFF%
ECHO vid2ani [input_file] [Arguments]
ECHO:
ECHO %GREEN%Arguments:%OFF%
ECHO:
ECHO	-t	Output file type.
ECHO		%YELLOW%Valid: 'gif' (default), 'png', 'webp'.%OFF%
ECHO:
ECHO	-o	Output file.
ECHO		%YELLOW%The default is the same name as the input video.%OFF%
ECHO:
ECHO	-r	Scale or size.
ECHO		%CYAN%Width of the animation in pixels.%OFF%
ECHO		%YELLOW%The default is the same scale as the original video.%OFF%
ECHO:
ECHO	-s	Start time of the animation %CYAN%(HH:MM:SS.MS)%OFF%
ECHO:
ECHO	-e	End time of the animation %CYAN%(HH:MM:SS.MS)%OFF%
ECHO:
ECHO	-f	Framerate in frames per second.
ECHO		%YELLOW%The default is 15.%OFF%
ECHO:
ECHO	-d	Dithering algorithm to be used.
ECHO		%YELLOW%The default is 0 (None).%OFF%
ECHO:
ECHO	-b	Bayer Scale setting.
ECHO		%CYAN%This can only be used when Bayer dithering is applied.
ECHO		%YELLOW%Range 0 - 5, default is 2.%OFF%
ECHO:
ECHO	-m	Palettegen mode - one of 3 modes listed below.
ECHO		%YELLOW%The default is 1 (diff).%OFF%
ECHO:
ECHO	-c	The maximum amount of colors useable per palette.
ECHO		%YELLOW%Range 3 - 256 (default)%OFF%
ECHO:
ECHO	-k	Enables paletteuse error diffusion.
ECHO:
ECHO	-l	Enable lossy WebP compression and quality.
ECHO		%CYAN%The default for WebP is lossless.%OFF%
ECHO		%YELLOW%Range 0 - 100, default 75.%OFF%
ECHO:
ECHO	-v	Set FFmpeg log level, for troubleshooting.
ECHO		%YELLOW%The default log level is 'error'%OFF%
ECHO:
ECHO	-p	Opens the resulting animation in your default Photo Viewer.
ECHO:

ECHO %GREEN%Dithering Mode%OFF%
ECHO 0: None
ECHO 1: Bayer
ECHO 2: Heckbert
ECHO 3: Floyd Steinberg
ECHO 4: Sierra2
ECHO 5: Sierra2_4a
ECHO 6: Sierra3
ECHO 7: Burkes
ECHO 8: Atkinson
ECHO:
ECHO %GREEN%Palettegen Modes%OFF%
ECHO 1: diff - only what moves affects the palette
ECHO 2: single - one palette per frame
ECHO 3: full - one palette for the whole animation
ECHO:
ECHO %GREEN%About Bayerscale%OFF%
ECHO When bayer dithering is selected, the Bayer Scale option defines the
ECHO scale of the pattern (how much the crosshatch pattern is visible).
ECHO A low value means more visible pattern for less banding, a higher value
ECHO means less visible pattern at the cost of more banding.
ECHO:
ECHO %GREEN%People who made this project come to fruition%OFF%
ECHO ubitux, Nabi KaramAliZadeh, and the very kind and patient people in the
ECHO Batch Discord Server. Without these people's contributions, this script
ECHO would not be possible. Thank you all for your contributions and
ECHO assistance^^!
GOTO :EOF
