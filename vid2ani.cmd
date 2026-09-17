:: Description: Video to GIF/APNG/WEBP converter
:: By: MDHEXT, Nabi KaramAliZadeh, Pathduck
:: Version: 6.1
:: Url: https://github.com/Pathduck/vid2ani/
:: License: GNU General Public License v3.0 (GPLv3)
@echo off

:: Enable delayed variable expension
setlocal enabledelayedexpansion

:: Define ANSI Colors
set "off=[0m"
set "red=[91m"
set "green=[32m"
set "yellow=[33m"
set "blue=[94m"
set "cyan=[96m"

:: Check for blank input or help commands
if "%~1"=="" goto :help_message
if "%~1"=="-?" goto :help_message
if "%~1"=="/?" goto :help_message
if "%~1"=="--help" goto :help_message

:: Check if FFmpeg exists on PATH, if not exit
where /q ffmpeg.exe || ( echo %red%FFmpeg not found in PATH, please install it first%off% & goto :EOF )

:: Assign input and output
set "input=%~1"
set "output=%~n1"

:: Validate input file
if not exist "%input%" (
	echo %red%Input file not found: !input! %off%
	goto :EOF
)

:: Clearing input vars and setting defaults
set "fps=15"
set "mode=1"
set "dither=0"
set "scale=-1"
set "filetype=gif"
set "loglevel=error"
set "webp_lossy_q=75"
set "webp_lossy="
set "bayerscale="
set "colormax="
set "start_time="
set "end_time="
set "crop="
set "errorswitch="
set "picswitch="
set "playswitch="

:varin
:: Parse Arguments, first shift input one left
shift
:parse_loop
if not "%~1"=="" (
	if "%~1"=="-o" set "output=%~dpn2" & shift
	if "%~1"=="-t" set "filetype=%~2" & shift
	if "%~1"=="-r" set "scale=%~2" & shift
	if "%~1"=="-l" ( if 1%2 neq +1%2 ( set "webp_lossy=1"
		) else if "%~2"=="" ( set "webp_lossy=1"
		) else ( set "webp_lossy=1" & set "webp_lossy_q=%~2" & shift )
	)
	if "%~1"=="-f" set "fps=%~2" & shift
	if "%~1"=="-s" set "start_time=%~2" & shift
	if "%~1"=="-e" set "end_time=%~2" & shift
	if "%~1"=="-d" set "dither=%~2" & shift
	if "%~1"=="-b" set "bayerscale=%~2" & shift
	if "%~1"=="-m" set "mode=%~2" & shift
	if "%~1"=="-c" set "colormax=%~2" & shift
	if "%~1"=="-v" set "loglevel=%~2" & shift
	if "%~1"=="-x" set "crop=%~2" & shift
	if "%~1"=="-k" set "errorswitch=1"
	if "%~1"=="-p" set "picswitch=1"
	if "%~1"=="-y" set "playswitch=1"
	shift & goto :parse_loop
)

:safchek
:: Validate if output file is set and not starts with a -
if "%output%"=="" ( echo %red%Missing value for -o%off% & goto :EOF )
for %%f in ("%output%") do set "out_base=%%~nf"
if defined out_base (
	if "!out_base:~0,1!"=="-" ( echo %red%Missing value for -o%off% & goto :EOF )
)

:: Validate if output is a directory; strip trailing slash and use input filename
if exist "%output%\*" (
	if "%output:~-1%"=="\" set "output=%output:~0,-1%"
	for %%f in ("!input!") do set "filename=%%~nf"
	set "output=!output!\!filename!"
)

:: Validate output file extension
echo %filetype% | findstr /r "\<gif\> \<png\> \<apng\> \<webp\>" >nul
if errorlevel 1 (
	echo %red%Not a valid file type: !filetype!%off%
	goto :EOF
)
if "%filetype%"=="gif" set "output=%output%.gif"
if "%filetype%"=="webp" set "output=%output%.webp"
if "%filetype%"=="png" set "filetype=apng"
if "%filetype%"=="apng" set "output=%output%.png"

:: Validate Palettegen
if !mode! gtr 3 (
	echo %red%Not a valid palettegen ^(-m^) mode.%off%
	goto :EOF
) else if !mode! lss 1 (
	echo %red%Not a valid palettegen ^(-m^) mode.%off%
	goto :EOF
)

:: Validate Dithering
if !dither! gtr 8 (
	echo %red%Not a valid dither ^(-d^) algorithm.%off%
	goto :EOF
) else if !dither! lss 0 (
	echo %red%Not a valid dither ^(-d^) algorithm.%off%
	goto :EOF
)

:: Validate Bayerscale
if defined bayerscale (
	if !bayerscale! gtr 5 (
		echo %red%Not a valid bayerscale ^(-b^) value.%off%
		goto :EOF
	) else if !bayerscale! lss 0 (
		echo %red%Not a valid bayerscale ^(-b^) value.%off%
		goto :EOF
	)
	if !dither! neq 1 (
		if !bayerscale! leq 5 (
			echo %red%Bayerscale ^(-b^) only works with Bayer dithering.%off%
			goto :EOF
		)
	)
)

:: Validate Lossy WEBP
if defined webp_lossy (
	if not "!filetype!"=="webp" (
		echo %red%Lossy ^(-l^) is only valid for filetype webp.%off%
		goto :EOF
	) else if !webp_lossy_q! gtr 100 (
		echo %red%Not a valid lossy ^(-l^) quality value.%off%
		goto :EOF
	) else if !webp_lossy_q! lss 0 (
		echo %red%Not a valid lossy ^(-l^) quality value.%off%
		goto :EOF
	)
)

:: Validate Clipping
if defined start_time (
	if defined end_time set "trim=-ss !start_time! -to !end_time!"
	if not defined end_time (
		echo %red%End time ^(-e^) is required when Start time ^(-s^) is specified.%off%
		goto :EOF
	)
)
if defined end_time (
	if not defined start_time (
		echo %red%Start time ^(-s^) is required when End time ^(-e^) is specified.%off%
		goto :EOF
	)
)

:: Validate Max Colors
if defined colormax (
	if !colormax! gtr 256 (
		echo  %red%Max colors ^(-c^) must be between 3 and 256.%off%
		goto :EOF
	)
	if !colormax! lss 3 (
		echo  %red%Max colors ^(-c^) must be between 3 and 256.%off%
		goto :EOF
	)
)

:: Validate Framerate
if "!fps!"=="-" (
	set "fps=source_fps"
) else if !fps! lss 1 (
	echo  %red%Framerate ^(-f^) must be greater than 0.%off%
	goto :EOF
)

:script_start
:: Putting together filters
set "filters=fps=%fps%"
if defined crop ( set "filters=%filters%,crop=%crop%" )
set "filters=%filters%,scale=%scale%:-1:flags=lanczos"

:: FFplay preview
if defined playswitch (
:: Check if ffplay exists on PATH, if not exit
	where /q ffplay.exe || ( echo %red%FFplay not found in PATH, please install it first%off% & goto :EOF )

	for /f "delims=" %%a in ('ffplay -version') do (
		if not defined ffplay_version ( set "ffplay_version=%%a"
		 ) else if not defined ffplay_build ( set "ffplay_build=%%a" )
	)
	echo %yellow%!ffplay_version!%off%
	echo %yellow%!ffplay_build!%off%

	if not defined start_time set "start_time=0"
	if not defined end_time set "end_time=3"
	ffplay -v %loglevel% -i "%input%" -vf "%filters%" -an -loop 0 -ss !start_time! -t !end_time!
	goto :EOF
)

:palettegen
:: APNG muxer does not support multiple palettes, fallback to palettegen diff mode
if "%filetype%"=="apng" (
	if !mode! equ 2 (
		echo %yellow%APNG does not support multiple palettes, falling back to Palettegen mode 1 ^(diff^).%off%
		set mode=1
	)
)

:: Palettegen encode mode
if !mode! equ 1 set "encode=palettegen=stats_mode=diff"
if !mode! equ 2 set "encode=palettegen=stats_mode=single"
if !mode! equ 3 set "encode=palettegen"

:: Max colors
if defined colormax (
	if !mode! leq 2 set "mcol=:max_colors=!colormax!"
	if !mode! equ 3 set "mcol==max_colors=!colormax!"
)

:: Storing FFmpeg version string
for /f "delims=" %%a in ('ffmpeg -version') do (
	if not defined ffmpeg_version ( set "ffmpeg_version=%%a"
	) else if not defined ffmpeg_build ( set "ffmpeg_build=%%a" )
)

:: Displaying FFmpeg version string and output file
echo %yellow%!ffmpeg_version!%off%
echo %yellow%!ffmpeg_build!%off%
echo %green%Output file:%off% !output!

:: Creating working dir
set WD=%TEMP%\vid2ani-%random%
set palette=%WD%\palette_%%05d.png
md "%WD%"

:: Executing command to generate palette
echo %green%Generating palette...%off%
ffmpeg -v %loglevel% %trim% -i "%input%" -vf "%filters%,%encode%%mcol%" -y "%palette%"

:: Checking if the palette file is in the Working Directory, if not cleaning up
if not exist "%WD%\palette_00001.png" (
	echo %red%Palette generation failed: !palette! not found.%off%
	goto :cleanup
)

:: Setting variables to put the encode command together

:: Palettegen decode mode
if !mode! equ 1 set "decode=paletteuse"
if !mode! equ 2 set "decode=paletteuse=new=1"
if !mode! equ 3 set "decode=paletteuse"

:: Error diffusion
if defined errorswitch (
	if !mode! equ 1 set "errordiff==diff_mode=rectangle"
	if !mode! equ 2 set "errordiff=:diff_mode=rectangle"
	if !mode! equ 3 set "errordiff==diff_mode=rectangle"
)

:: Prepare dithering and encoding options
if !dither! equ 0 set "ditheralg=none"
if !dither! equ 1 set "ditheralg=bayer"
if !dither! equ 2 set "ditheralg=heckbert"
if !dither! equ 3 set "ditheralg=floyd_steinberg"
if !dither! equ 4 set "ditheralg=sierra2"
if !dither! equ 5 set "ditheralg=sierra2_4a"
if !dither! equ 6 set "ditheralg=sierra3"
if !dither! equ 7 set "ditheralg=burkes"
if !dither! equ 8 set "ditheralg=atkinson"

:: Paletteuse error diffusion
if not !mode! equ 2 (
	if defined errorswitch set "ditherenc=:dither=!ditheralg!"
	if not defined errorswitch set "ditherenc==dither=!ditheralg!"
) else set "ditherenc=:dither=!ditheralg!"

:: Checking for Bayer Scale and adjusting command
if defined bayerscale (
	set "bayer=:bayer_scale=!bayerscale!"
) else set "bayer="

:: WEBP pixel format and lossy quality
if "%filetype%"=="webp" (
	if defined webp_lossy (
		set "type_opts=-lossless 0 -pix_fmt yuva420p -quality !webp_lossy_q!"
	) else set "type_opts=-lossless 1"
)

:: Executing the encoding command
echo %green%Encoding animation...%off%
ffmpeg -v %loglevel% %trim% -i "%input%" -thread_queue_size 512 -i "%palette%" ^
-lavfi "%filters% [x]; [x][1:v] %decode%%errordiff%%ditherenc%%bayer%" ^
-f %filetype% %type_opts% -loop 0 -plays 0 -y "%output%"

:: Checking if file was created and cleaning up if not
if not exist "%output%" (
	echo %red%Failed to generate animation: !output! not found.%off%
	goto :cleanup
)

:: Open output file if picswitch is set
if defined picswitch start "" "%output%"

:cleanup
:: Cleaning up
rmdir /s /q "%WD%"
echo %green%Done.%off%
endlocal
goto :EOF

:help_message
:: Print usage message
echo %green%Video to Gif/APNG/WEBP converter v6.1%off%
echo %blue%By MDHEXT, Nabi KaramAliZadeh, Pathduck%off%
echo:
echo %green%Usage:%off%
echo %~n0 [input_file] [arguments]
echo:
echo %green%Arguments:%off%
echo  -o  Output file. Default is the same as input file, sans extension
echo  -t  Output file type: 'gif' (default), 'apng', 'png', 'webp'
echo  -r  Resize output width in pixels. Default is original input size
echo  -l  Enable lossy WebP compression and quality, range 0-100 (default 75)
echo  -f  Framerate of output, or '-' to use input framerate (default 15)
echo  -c  Maximum colors usable per palette, range 3-256 (default 256)
echo  -s  Start time of the animation (HH:MM:SS.MS)
echo  -e  End time of the animation (HH:MM:SS.MS)
echo  -x  Crop the input video (out_w:out_h:x:y)
echo      Note that cropping occurs before output is scaled
echo  -d  Dithering algorithm to be used (default 0)
echo  -b  Bayer Scale setting, range 0-5 (default 2)
echo  -m  Palettegen mode: 1 (diff, default), 2 (single), 3 (full)
echo  -k  Enables paletteuse error diffusion
echo  -y  Preview animation using FFplay (part of FFmpeg)
echo      Useful for testing cropping, but will not use exact start/end time
echo  -p  Opens the resulting animation in the default image viewer
echo  -v  Set FFmpeg log level (default: error)
echo:
echo %green%Dithering Algorithms:%off%
echo  0: None
echo  1: Bayer
echo  2: Heckbert
echo  3: Floyd Steinberg
echo  4: Sierra2
echo  5: Sierra2_4a
echo  6: Sierra3
echo  7: Burkes
echo  8: Atkinson
echo:
echo %green%Palettegen Modes:%off%
echo  1: diff - only what moves affects the palette
echo  2: single - one palette per frame
echo  3: full - one palette for the whole animation
echo:
echo %green%About Bayerscale:%off%
echo When bayer dithering is selected, the Bayer Scale option defines the
echo scale of the pattern (how much the crosshatch pattern is visible).
echo A low value means more visible pattern for less banding, a higher value
echo means less visible pattern at the cost of more banding.
echo:
echo %green%People who made this project come to fruition:%off%
echo ubitux, Nabi KaramAliZadeh, MDHEXT, Pathduck
echo Along with the very kind and patient people in the Batch Discord Server.
echo Without these people's contributions, this script would not be possible.
echo Thank you all for your contributions and assistance^^!
goto :EOF
