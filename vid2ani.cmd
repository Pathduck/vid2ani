@ECHO OFF
:: Description: Video to GIF/APNG/WEBP converter
:: By: MDHEXT, Nabi KaramAliZadeh, Pathduck
:: Version: 6.0
:: Url: https://github.com/Pathduck/vid2ani/ forked from https://github.com/MDHEXT/video2gif
:: What this script is based on: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
:: License: GNU General Public License v3.0 (GPLv3)

:: Enable delayed variable expension
SETLOCAL ENABLEDELAYEDEXPANSION

:: Storing Paths
SET input="%~1"
SET vid="%~dpnx1"
SET output=%~dpn1
SET FILEPATH=%~dp1

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
	ECHO [91mNot a valid file type[0m
	GOTO :EOF
)
IF "%filetype%"=="png" SET filetype=apng
IF "%filetype%"=="apng" SET output=%output%.png
IF "%filetype%"=="webp" SET output=%output%.webp
IF "%filetype%"=="gif" SET output=%output%.gif

:: Palettegen
IF %mode% GTR 3 (
	ECHO [91mNot a valid palettegen mode[0m
	GOTO :EOF
) ELSE IF %mode% LSS 1 (
	ECHO [91mNot a valid palettegen mode[0m
	GOTO :EOF
)
:: Dithering
IF %dither% GTR 8 (
	ECHO [91mNot a valid dither algorithm[0m
	GOTO :EOF
) ELSE IF %dither% LSS 0 (
	ECHO [91mNot a valid dither algorithm[0m
	GOTO :EOF
)

::  Bayerscale
IF DEFINED bayerscale (
	IF !bayerscale! GTR 5 (
		ECHO [91mNot a valid bayerscale value[0m
		GOTO :EOF
	) ELSE IF !bayerscale! LSS 0 (
		ECHO [91mNot a valid bayerscale value[0m
		GOTO :EOF
	)
	IF !bayerscale! LEQ 5 (
		IF %dither% NEQ 1 (
			ECHO [91mThis setting only works with bayer dithering[0m
			GOTO :EOF
		)
	)
)

:: Lossy WEBP
IF DEFINED webp_lossy (
	IF NOT "%filetype%" == "webp" (
		ECHO [91mLossy is only valid for filetype webp[0m
		GOTO :EOF
	) ELSE IF !webp_lossy! GTR 100 (
		ECHO [91mNot a valid lossy quality value[0m
		GOTO :EOF
	) ELSE IF !webp_lossy! LSS 0 (
		ECHO [91mNot a valid lossy quality value[0m
		GOTO :EOF
	)
)

:: Noob Proofing clipping
IF DEFINED start_time (
	IF DEFINED end_time SET "trim=-ss !start_time! -to !end_time!"
	IF NOT DEFINED end_time (
		ECHO [91mPlease input the end time[0m
		GOTO :EOF
	)
)

IF NOT DEFINED start_time (
	IF DEFINED end_time (
		ECHO [91mPlease input the start time[0m
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
ECHO [33m%version%[0m
ECHO [33m%build%[0m
ECHO [92mOutput file: %output%[0m
ECHO [32mCreating working directory...[0m
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
ECHO [32mGenerating palette...[0m
ffmpeg -v %loglevel% %trim% -i %vid% -vf "%filters%,%encode%%mcol%" -y "%frames%.png"

:: Checking if the palette file is in the Working Directory, if not cleaning up
IF NOT EXIST "%palette%_00001.png" (
	IF NOT EXIST "%palette%.png" (
		ECHO [91mFailed to generate palette file[0m
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
		SET "webp_lossy=-lossless 0 -pix_fmt yuv420p -quality %webp_lossy%"
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
ECHO [32mEncoding animation...[0m
ffmpeg -v %loglevel% %trim% -i %vid% -thread_queue_size 512 -i "%frames%.png" -lavfi "%filters% [x]; [x][1:v] %decode%%errordiff%%ditherenc%%bayer%" -f %filetype% %webp_lossy% -loop 0 -plays 0 -y "%output%"

:: Checking if file was created and cleaning up if not
IF NOT EXIST "%output%" (
	ECHO [91mFailed to generate animation[0m
	GOTO :cleanup
)

:: Starting default Photo Viewer
IF DEFINED picswitch START "" "%output%"

:cleanup
:: Cleaning up
ECHO [32mDeleting temporary files...[0m
RMDIR /S /Q "%WD%"
ENDLOCAL
ECHO [93mDone![0m
GOTO :EOF

:help_message
:: Print usage message
ECHO:
ECHO [92mVideo to GIF/APNG/WEBP converter v6.0[0m
ECHO [96mBy MDHEXT, Nabi KaramAliZadeh, Pathduck[0m
ECHO:
ECHO You can download this fork from here:[0m
ECHO [96mhttps://github.com/Pathduck/vid2ani/[0m
ECHO You can download the original release here:
ECHO [96mhttps://github.com/NabiKAZ/video2gif[0m
ECHO This tool uses ffmpeg, you can download that here:
ECHO [96mhttps://www.ffmpeg.org/download.html#build-windows[0m
ECHO This tool wouldn't be possible without the research listed here:
ECHO [96mhttps://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html[0m
ECHO:
ECHO [92mUsage:[0m
ECHO vid2ani [input_file] [Arguments]
ECHO:
ECHO [92mArguments:[0m
ECHO:
ECHO	-t	Output file type.
ECHO		[33mValid: 'gif' (default), 'png', 'webp'.[0m
ECHO:
ECHO	-o	Output file.
ECHO		[33mThe default is the same name as the input video.[0m
ECHO:
ECHO	-r	Scale or size.
ECHO		[96mWidth of the animation in pixels.[0m
ECHO		[33mThe default is the same scale as the original video.[0m
ECHO:
ECHO	-s	Start time of the animation [96m(HH:MM:SS.MS)[0m
ECHO:
ECHO	-e	End time of the animation [96m(HH:MM:SS.MS)[0m
ECHO:
ECHO	-f	Framerate in frames per second.
ECHO		[33mThe default is 15.[0m
ECHO:
ECHO	-d	Dithering algorithm to be used.
ECHO		[33mThe default is 0 (None).[0m
ECHO:
ECHO	-b	Bayer Scale setting.
ECHO		[96mThis can only be used when Bayer dithering is applied.
ECHO		[33mRange 0 - 5, default is 2.[0m
ECHO:
ECHO	-m	Palettegen mode - one of 3 modes listed below.
ECHO		[33mThe default is 1 (diff).[0m
ECHO:
ECHO	-c	The maximum amount of colors useable per palette.
ECHO		[33mRange 3 - 256 (default)[0m
ECHO:
ECHO	-k	Enables paletteuse error diffusion.
ECHO:
ECHO	-l	Enable lossy WebP compression and quality.
ECHO		[96mThe default for WebP is lossless.[0m
ECHO		[33mRange 0 - 100, default 75.[0m
ECHO:
ECHO	-v	Set FFmpeg log level, for troubleshooting.
ECHO		[33mThe default log level is 'error'[0m
ECHO:
ECHO	-p	Opens the resulting animation in your default Photo Viewer.
ECHO:
ECHO [92mDithering Modes:[0m
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
ECHO [92mPalettegen Modes:[0m
ECHO 1: diff - only what moves affects the palette
ECHO 2: single - one palette per frame
ECHO 3: full - one palette for the whole animation
ECHO:
ECHO [92mAbout Bayerscale:[0m
ECHO When bayer dithering is selected, the Bayer Scale option defines the
ECHO scale of the pattern (how much the crosshatch pattern is visible).
ECHO A low value means more visible pattern for less banding, a higher value
ECHO means less visible pattern at the cost of more banding.
ECHO:
ECHO [92mPeople who made this project come to fruition:[0m
ECHO ubitux, Nabi KaramAliZadeh, and the very kind and patient people in the
ECHO Batch Discord Server. Without these people's contributions, this script
ECHO would not be possible. Thank you all for your contributions and
ECHO assistance^^!
GOTO :EOF
