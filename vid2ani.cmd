@ECHO OFF
:: By: MDHEXT, Nabi KaramAliZadeh <nabikaz@gmail.com>
:: Description: Video to GIF/APNG/WEBP converter
:: Version: 5.5
:: Url: https://github.com/MDHEXT/video2gif, forked from https://github.com/NabiKAZ/video2gif
:: What this script is based on: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
:: License: GNU General Public License v3.0 (GPLv3)

:: Enable delayed variable expension
SETLOCAL ENABLEDELAYEDEXPANSION

:: Storing Paths
SET input="%~1"
SET vid="%~dpnx1"
SET output=%~dpn1
SET FILEPATH=%~dp1

:: Clearing all variables
SET "filetype="
SET "scale="
SET "fps="
SET "mode="
SET "dither="
SET "bayerscale="
SET "start_time="
SET "webp_lossy="
SET "duration="
SET "colormax="
SET "version="
SET "build="

:: Setting the path to the Working Directory and storing FFmpeg Version String
SET WD=%TEMP%\VID2ANI
SET palette=%WD%\template
FOR /F "delims=" %%a in ('ffmpeg -version') DO (
	IF NOT DEFINED version (
		SET "version=%%a"
	) ELSE IF NOT DEFINED build (
		SET "build=%%a"
	)
)
GOTO :help_check_1

:help_message
:: Print usage message
ECHO:
ECHO [32mVideo to GIF/APNG/WEBP converter v5.5[0m
ECHO [96m^(C^) 2017-2022, MDHEXT ^&^ Nabi KaramAliZadeh ^<nabikaz@gmail.com^>[0m
ECHO:
ECHO You can download this fork from here:[0m
ECHO [96mhttps://github.com/MDHEXT/video2gif[0m
ECHO You can download the original release here:
ECHO [96mhttps://github.com/NabiKAZ/video2gif[0m
ECHO This tool uses ffmpeg, you can download that here:
ECHO [96mhttps://www.ffmpeg.org/download.html#build-windows[0m
ECHO This tool wouldn't be possible without the research listed here:
ECHO [96mhttps://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html[0m
ECHO:
ECHO [32mUsage:[0m
ECHO vid2ani [input_file] [Arguments]
ECHO:
ECHO [32mArguments:[0m
ECHO	-t	Output filetype: gif, png, webp.
ECHO		[33mThe default is gif.[0m
ECHO	-o	Output file.
ECHO		[33mThe default is the same name as the input video.[0m
ECHO	-r	Scale or size.
ECHO		[96mWidth of the animation in pixels.[0m
ECHO		[33mThe default is the same scale as the original video.[0m
ECHO	-f	Framerate in frames per second.
ECHO		[33mThe default is 15.[0m
ECHO	-m	Palettegen mode - one of 3 modes listed below.
ECHO		[33mThe default is 1 (diff).[0m
ECHO	-d	Dithering algorithm to be used.
ECHO		[33mThe default is 0 (None).[0m
ECHO	-b	Bayer Scale setting. [96m(Optional)[0m
ECHO		[96mThis can only be used when Bayer dithering is applied.
ECHO		See more information below.[0m
ECHO	-l	Set lossy WebP compression and quality
ECHO		[33mValue 0-100, default 75.[0m
ECHO		[96m(Default for WebP is lossless)[0m
ECHO	-c	The maximum amount of colors useable per palette.
ECHO		[96m(Optional value up to 256)[0m
ECHO		[33mThis option isn't used by default.[0m
ECHO	-s	Start of the animation (HH:MM:SS.MS)
ECHO		[96m(Optional)[0m
ECHO	-e	Duration of the animation (HH:MM:SS.MS)
ECHO		[96m(Optional)[0m
ECHO	-k	Enables error diffusion.
ECHO		[96m(Optional)[0m
ECHO	-p	Opens the resulting animation in your default Photo Viewer.
ECHO		[96m(Optional)[0m
ECHO:
ECHO [32mPalettegen Modes:[0m
ECHO 1: diff - only what moves affects the palette
ECHO 2: single - one palette per frame
ECHO 3: full - one palette for the whole animation
ECHO:
ECHO [32mDithering Options:[0m
ECHO 0: None
ECHO 1: Bayer
ECHO 2: Heckbert
ECHO 3: Floyd Steinberg
ECHO 4: Sierra2
ECHO 5: Sierra2_4a
ECHO 6: sierra3
ECHO 7: burkes
ECHO 8: atkinson
ECHO:
ECHO [32mAbout Bayerscale:[0m
ECHO When bayer dithering is selected, the Bayer Scale option defines the
ECHO scale of the pattern (how much the crosshatch pattern is visible).
ECHO A low value means more visible pattern for less banding, a higher value
ECHO means less visible pattern at the cost of more banding.
ECHO [96mThe option must be an integer value in the range [0,5].[0m
ECHO [33mThe Default is 2.[0m [96mBayer Scale is optional.[0m
ECHO:
ECHO [95mPeople who made this project come to fruition:[0m
ECHO ubitux, Nabi KaramAliZadeh, and the very kind and patient people in the
ECHO Batch Discord Server. Without these people's contributions, this script
ECHO would not be possible. Thank you all for your contributions and
ECHO assistance^^!
GOTO :EOF

:help_check_1
:: Checking for blank input or help commands
IF %input% == "" GOTO :help_message
IF %input% == "help" GOTO :help_message
IF %input% == "-?" GOTO :help_message
IF %input% == "--help" GOTO :help_message
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
	IF "%~1" =="-o" SET "output=%~dpnx2" & SHIFT
	IF "%~1" =="-s" SET "start_time=%~2" & SHIFT
	IF "%~1" =="-e" SET "duration=%~2" & SHIFT
	IF "%~1" =="-c" SET "colormax=%~2" & SHIFT
	IF "%~1" =="-l" SET "webp_lossy=%~2" & SHIFT
	IF "%~1" =="-k" SET "errorswitch=0"
	IF "%~1" =="-p" SET "picswitch=0"
	SHIFT & GOTO :varin
)
GOTO :help_check_2

:help_check_2
:: Noob proofing the script to prevent it from breaking should critical settings not be defined
IF NOT DEFINED filetype SET "filetype=gif"
IF NOT DEFINED scale SET "scale=-1"
IF NOT DEFINED fps SET fps=15
IF NOT DEFINED mode SET mode=1
IF NOT DEFINED dither SET dither=0
GOTO :safchek

:safchek
:: Setting a clear range of acceptable setting values and noob proofing bayerscale
echo %filetype% | findstr /r "\<gif\> \<png\> \<apng\> \<webp\>" >nul
IF %errorlevel% NEQ 0 (
	ECHO  [91mNot a valid file type[0m
	GOTO :EOF
)

IF %mode% GTR 3 (
	ECHO [91mNot a valid mode[0m
	GOTO :EOF
) ELSE IF %mode% LSS 1 (
	ECHO [91mNot a valid mode[0m
	GOTO :EOF
)

IF %dither% GTR 8 (
	ECHO [91mNot a valid dither algorithm[0m
	GOTO :EOF
) ELSE IF %dither% LSS 0 (
	ECHO [91mNot a valid dither algorithm[0m
	GOTO :EOF
)

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

IF DEFINED bayerscale (
	IF !bayerscale! GTR 5 (
		ECHO [91mNot a valid bayerscale value[0m
		GOTO :EOF
	) ELSE IF !bayerscale! LSS 0 (
		ECHO [91mNot a valid bayerscale value[0m
		GOTO :EOF
	)
	IF !bayerscale! LEQ 5 (
		IF %dither% EQU 1 GOTO :script_start
		IF %dither% NEQ 1 (
			ECHO [91mThis setting only works with bayer dithering[0m
			GOTO :EOF
		)
	)
)
GOTO :script_start

:script_start
:: Set output file name
IF "%filetype%"=="png" SET filetype=apng
IF "%filetype%"=="apng" SET output=%output%.png
IF "%filetype%"=="webp" SET output=%output%.webp
IF "%filetype%"=="gif" SET output=%output%.gif

:: Displaying FFmpeg Version String and Creating the Working Directory
ECHO [33m%version%[0m
ECHO [33m%build%[0m
ECHO [32mOutput file: %output%[0m
ECHO [32mCreating Working Directory...[0m
MD "%WD%"

:palettegen
:: Noob Proofing clipping
IF DEFINED start_time (
	IF DEFINED duration SET "trim=-ss !start_time! -t !duration!"
	IF NOT DEFINED duration (
		ECHO [35mPlease input a duration[0m
		GOTO :cleanup
	)
)

IF NOT DEFINED start_time (
	IF DEFINED duration (
		ECHO [35mPlease input a start time[0m
		GOTO :cleanup
	)
)

:: Putting together command to generate palette
SET frames=%palette%_%%05d
SET filters=fps=%fps%,scale=%scale%:-1:flags=lanczos

IF %mode% EQU 1 SET encode=palettegen=stats_mode=diff
IF %mode% EQU 2 SET encode="palettegen=stats_mode=single"
IF %mode% EQU 3 SET encode=palettegen

IF DEFINED colormax (
	IF %mode% LEQ 2 SET "mcol=:max_colors=%colormax%"
	IF %mode% EQU 3 SET "mcol==max_colors=%colormax%"
)

:: Executing command to generate palette
ECHO [32mGenerating Palette...[0m
ffmpeg -v warning %trim% -i %vid% -vf "%filters%,%encode%%mcol%" -y "%frames%.png"

:: Checking if the palette file is in the Working Directory, if not cleaning up
IF NOT EXIST "%palette%_00001.png" (
	IF NOT EXIST "%palette%.png" (
		ECHO [91mFailed to generate palette file[0m
		GOTO :cleanup
	)
)

:: Setting variables to put the command together
:: Checking for Error Diffusion if using Bayer Scale and adjusting the command accordingly
IF %mode% EQU 1 SET decode=paletteuse
IF %mode% EQU 2 SET "decode=paletteuse=new=1"
IF %mode% EQU 3 SET decode=paletteuse

IF DEFINED errorswitch (
	IF %mode% EQU 1 SET "errordiff==diff_mode=rectangle"
	IF %mode% EQU 2 SET "errordiff=:diff_mode=rectangle"
	IF %mode% EQU 3 SET "errordiff==diff_mode=rectangle"
)

:: Setting WEBP lossy arguments
IF "%filetype%" == "webp" (
	IF DEFINED webp_lossy (
		SET "webp_lossy=-lossless 0 -pix_fmt yuv420p -quality %webp_lossy%"
	) ELSE SET "webp_lossy=-lossless 1"
)

:: Setting dither algorithm
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
ffmpeg -v warning %trim% -i %vid% -thread_queue_size 512 -i "%frames%.png" -lavfi "%filters% [x]; [x][1:v] %decode%%errordiff%%ditherenc%%bayer%" -f %filetype% %webp_lossy% -loop 0 -plays 0 -y "%output%"

:: Checking if file was created and cleaning up if not
IF NOT EXIST "%output%" (
	ECHO [91mFailed to generate animation[0m
	GOTO :cleanup
)

:: Starting default Photo Viewer
IF DEFINED picswitch START "" "%output%"

:cleanup
:: Cleaning up
ECHO [32mDeleting Temporary files...[0m
RMDIR /S /Q "%WD%"
ENDLOCAL
ECHO [93mDone![0m
