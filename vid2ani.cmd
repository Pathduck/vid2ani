@ECHO OFF
:: Description: Video to GIF/APNG/WEBP converter
:: By: MDHEXT, Nabi KaramAliZadeh, Pathduck
:: Version: 6.0
:: Url: https://github.com/Pathduck/vid2ani/ forked from https://github.com/MDHEXT/video2gif
:: What this script is based on: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
:: License: GNU General Public License v3.0 (GPLv3)

:: Enable delayed variable expension
SETLOCAL ENABLEDELAYEDEXPANSION

:: Define ANSI Colors
SET "OFF=[0m"
SET "RED=[91m"
SET "GREEN=[32m"
SET "YELLOW=[33m"
SET "BLUE=[94m"
SET "CYAN=[96m"

:: Checking for blank input or help commands
IF "%~1" == "" GOTO :help_message
IF "%~1" == "-?" GOTO :help_message
IF "%~1" == "/?" GOTO :help_message
IF "%~1" == "--help" GOTO :help_message

:: Assign input and output
SET input="%~1"
SET output=%~dpn1

:: Validate input file
IF NOT EXIST %input% (
	ECHO %RED%Input file not found: %input%%OFF%
	GOTO :EOF
)

:: Setting the path to the working directory
SET WD=%TEMP%\VID2ANI

:: Clearing input vars and setting defaults
SET "fps=15"
SET "mode=1"
SET "dither=0"
SET "scale=-1"
SET "filetype=gif"
SET "webp_lossy="
SET "webp_lossy_def=75"
SET "loglevel=error"
SET "bayerscale="
SET "colormax="
SET "start_time="
SET "end_time="
SET "errorswitch="
SET "picswitch="

GOTO :varin

:varin
:: Using SHIFT command to go through the input and storing each setting into its own variable
IF NOT "%~1" =="" (
	IF "%~1" =="-o" SET "output=%~dpn2" & SHIFT
	IF "%~1" =="-t" SET "filetype=%~2" & SHIFT
	IF "%~1" =="-r" SET "scale=%~2" & SHIFT
	IF "%~1" =="-l" ( IF 1%2 NEQ +1%~2 ( SET "webp_lossy=%webp_lossy_def%"
		) ELSE IF "%~2" == "" ( SET "webp_lossy=%webp_lossy_def%"
		) ELSE ( SET "webp_lossy=%~2" & SHIFT )
	)
	IF "%~1" =="-f" SET "fps=%~2" & SHIFT
	IF "%~1" =="-s" SET "start_time=%~2" & SHIFT
	IF "%~1" =="-e" SET "end_time=%~2" & SHIFT
	IF "%~1" =="-d" SET "dither=%~2" & SHIFT
	IF "%~1" =="-b" SET "bayerscale=%~2" & SHIFT
	IF "%~1" =="-m" SET "mode=%~2" & SHIFT
	IF "%~1" =="-c" SET "colormax=%~2" & SHIFT
	IF "%~1" =="-v" SET "loglevel=%~2" & SHIFT
	IF "%~1" =="-k" SET "errorswitch=1"
	IF "%~1" =="-p" SET "picswitch=1"
	SHIFT & GOTO :varin
)
GOTO :safchek

:safchek
:: Validate output file extension
echo %filetype% | findstr /r "\<gif\> \<png\> \<apng\> \<webp\>" >nul
IF %errorlevel% NEQ 0 (
	ECHO %RED%Not a valid file type: %filetype%%OFF%
	GOTO :EOF
)
IF "%filetype%"=="gif" SET "output=%output%.gif"
IF "%filetype%"=="png" SET "filetype=apng"
IF "%filetype%"=="apng" SET "output=%output%.png"
IF "%filetype%"=="webp" SET "output=%output%.webp"

:: Validate Palettegen
IF !mode! GTR 3 (
	ECHO %RED%Not a valid palettegen ^(-m^) mode%OFF%
	GOTO :EOF
) ELSE IF !%mode! LSS 1 (
	ECHO %RED%Not a valid palettegen ^(-m^) mode%OFF%
	GOTO :EOF
)

:: Validate Dithering
IF !dither! GTR 8 (
	ECHO %RED%Not a valid dither ^(-d^) algorithm %OFF%
	GOTO :EOF
) ELSE IF !dither! LSS 0 (
	ECHO %RED%Not a valid dither ^(-d^) algorithm%OFF%
	GOTO :EOF
)

:: Validate Bayerscale
IF DEFINED bayerscale (
	IF !bayerscale! GTR 5 (
		ECHO %RED%Not a valid bayerscale ^(-b^) value %OFF%
		GOTO :EOF
	) ELSE IF !bayerscale! LSS 0 (
		ECHO %RED%Not a valid bayerscale ^(-b^) value%OFF%
		GOTO :EOF
	)
	IF !dither! NEQ 1 (
		IF !bayerscale! LEQ 5 (
			ECHO %RED%Bayerscale ^(-b^) only works with Bayer dithering%OFF%
			GOTO :EOF
		)
	)
)

:: Validate Lossy WEBP
IF DEFINED webp_lossy (
	IF NOT "%filetype%" == "webp" (
		ECHO %RED%Lossy ^(-l^) is only valid for filetype webp%OFF%
		GOTO :EOF
	) ELSE IF !webp_lossy! GTR 100 (
		ECHO %RED%Not a valid lossy ^(-l^) quality value%OFF%
		GOTO :EOF
	) ELSE IF !webp_lossy! LSS 0 (
		ECHO %RED%Not a valid lossy ^(-l^) quality value%OFF%
		GOTO :EOF
	)
)

:: Validate Clipping
IF DEFINED start_time (
	IF DEFINED end_time SET "trim=-ss !start_time! -to !end_time!"
	IF NOT DEFINED end_time (
		ECHO %RED%Please input the end time ^(-e^)%OFF%
		GOTO :EOF
	)
)
IF NOT DEFINED start_time (
	IF DEFINED end_time (
		ECHO %RED%Please input the start time ^(-s^)%OFF%
		GOTO :EOF
	)
)

:: Validate Framerate
IF DEFINED fps (
	IF !fps! LSS 0 (
		ECHO  %RED%Framerate ^(-f^) must be greater than 0.%OFF%
		GOTO :EOF
	)
)

:: Validate Max Colors
IF DEFINED colormax (
	IF !colormax! LSS 3 (
		ECHO  %RED%Max colors ^(-c^) must be between 3 and 256.%OFF%
		GOTO :EOF
	)
	IF !colormax! GTR 256 (
		ECHO  %RED%Max colors ^(-c^) must be between 3 and 256.%OFF%
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
SET palette=%WD%\palette_%%05d.png
SET filters=fps=%fps%,scale=%scale%:-1:flags=lanczos

:: APNG muxer does not support multiple palettes so fallback to using palettegen diff mode
IF "%filetype%"=="apng" (
	IF !mode! EQU 2 (
		ECHO %YELLOW%APNG does not support multiple palettes - falling back to Palettegen mode 1 ^(diff^)%OFF%
		SET mode=1
	)
)

:: Palettegen encode mode
IF !mode! EQU 1 SET "encode=palettegen=stats_mode=diff"
IF !mode! EQU 2 SET "encode=palettegen=stats_mode=single"
IF !mode! EQU 3 SET "encode=palettegen"

:: Max colors
IF DEFINED colormax (
	IF !mode! LEQ 2 SET "mcol=:max_colors=%colormax%"
	IF !mode! EQU 3 SET "mcol==max_colors=%colormax%"
)

:: Executing command to generate palette
ECHO %GREEN%Generating palette...%OFF%
ffmpeg -v %loglevel% %trim% -i %input% -vf "%filters%,%encode%%mcol%" -y "%palette%"

:: Checking if the palette file is in the Working Directory, if not cleaning up
IF NOT EXIST "%WD%\palette_00001.png" (
	ECHO %RED%Palette generation failed: %palette% not found.%OFF%
	GOTO :cleanup
)

:: Setting variables to put the encode command together

:: Palettegen decode mode
IF !mode! EQU 1 SET "decode=paletteuse"
IF !mode! EQU 2 SET "decode=paletteuse=new=1"
IF !mode! EQU 3 SET "decode=paletteuse"

:: Error diffusion
IF DEFINED errorswitch (
	IF !mode! EQU 1 SET "errordiff==diff_mode=rectangle"
	IF !mode! EQU 2 SET "errordiff=:diff_mode=rectangle"
	IF !mode! EQU 3 SET "errordiff==diff_mode=rectangle"
)

:: Prepare dithering and encoding options
IF !dither! EQU 0 SET "ditheralg=none"
IF !dither! EQU 1 SET "ditheralg=bayer"
IF !dither! EQU 2 SET "ditheralg=heckbert"
IF !dither! EQU 3 SET "ditheralg=floyd_steinberg"
IF !dither! EQU 4 SET "ditheralg=sierra2"
IF !dither! EQU 5 SET "ditheralg=sierra2_4a"
IF !dither! EQU 6 SET "ditheralg=sierra3"
IF !dither! EQU 7 SET "ditheralg=burkes"
IF !dither! EQU 8 SET "ditheralg=atkinson"

:: Paletteuse error diffusion
IF NOT !mode! EQU 2 (
	IF DEFINED errorswitch SET "ditherenc=:dither=!ditheralg!"
	IF NOT DEFINED errorswitch SET "ditherenc==dither=!ditheralg!"
) ELSE SET "ditherenc=:dither=!ditheralg!"

:: Checking for Bayer Scale and adjusting command
IF NOT DEFINED bayerscale SET "bayer="
IF DEFINED bayerscale SET "bayer=:bayer_scale=%bayerscale%"

:: WEBP pixel format and lossy quality
IF "%filetype%" == "webp" (
	IF DEFINED webp_lossy (
		SET "webp_lossy=-lossless 0 -pix_fmt yuva420p -quality %webp_lossy%"
	) ELSE SET "webp_lossy=-lossless 1"
)

:: Executing the encoding command
ECHO %GREEN%Encoding animation...%OFF%
ffmpeg -v %loglevel% %trim% -i %input% -thread_queue_size 512 -i "%palette%" -lavfi "%filters% [x]; [x][1:v] %decode%%errordiff%%ditherenc%%bayer%" -f %filetype% %webp_lossy% -loop 0 -plays 0 -y "%output%"

:: Checking if file was created and cleaning up if not
IF NOT EXIST "%output%" (
	ECHO %RED%Failed to generate animation: %output% not found.%OFF%
	GOTO :cleanup
)

:: Open output file if picswitch is set
IF DEFINED picswitch START "" "%output%"

:cleanup
:: Cleaning up
ECHO %GREEN%Deleting temporary files...%OFF%
RMDIR /S /Q "%WD%"
ECHO %GREEN%Done.%OFF%
ENDLOCAL
GOTO :EOF

:help_message
:: Print usage message
ECHO:
ECHO %GREEN%Video to GIF/APNG/WEBP converter v6.0%OFF%
ECHO %BLUE%By MDHEXT, Nabi KaramAliZadeh, Pathduck%OFF%
ECHO:
ECHO %GREEN%Usage:%OFF%
ECHO %~nx0 [input_file] [arguments]
ECHO:
ECHO %GREEN%Arguments:%OFF%
ECHO  -o  Output file. Default is the same as input file, sans extension.
ECHO  -t  Output file type. Valid: 'gif' (default), 'apng', 'png', 'webp'.
ECHO  -r  Scale or size. Width of the animation in pixels.
ECHO  -l  Enable lossy WebP compression and quality. Range 0-100, default 75.
ECHO  -f  Framerate in frames per seconds, default 15.
ECHO  -s  Start time of the animation (HH:MM:SS.MS).
ECHO  -e  End time of the animation (HH:MM:SS.MS).
ECHO  -d  Dithering algorithm to be used, default 0.
ECHO  -b  Bayer Scale setting. Range 0-5, default 2.
ECHO  -m  Palettegen mode: 1 (diff), 2 (single), 3 (full), default 1.
ECHO  -c  Maximum colors usable per palette. Range 3-256 (default).
ECHO  -k  Enables paletteuse error diffusion.
ECHO  -p  Opens the resulting animation in the system image viewer.
ECHO  -v  Set FFmpeg log level (default: error).
ECHO:
ECHO %GREEN%Dithering Algorithms%OFF%
ECHO  0: None
ECHO  1: Bayer
ECHO  2: Heckbert
ECHO  3: Floyd Steinberg
ECHO  4: Sierra2
ECHO  5: Sierra2_4a
ECHO  6: Sierra3
ECHO  7: Burkes
ECHO  8: Atkinson
ECHO:
ECHO %GREEN%Palettegen Modes%OFF%
ECHO  1: diff - only what moves affects the palette
ECHO  2: single - one palette per frame
ECHO  3: full - one palette for the whole animation
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
