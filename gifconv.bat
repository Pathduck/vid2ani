@ECHO OFF
:: By: MDHEXT, Nabi KaramAliZadeh <nabikaz@gmail.com>
:: Description: Video to GIF/APNG converter
:: Version: 5.5
:: Url: https://github.com/MDHEXT/video2gif, forked from https://github.com/NabiKAZ/video2gif
:: What this script is based on: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
:: License: GNU General Public License v3.0 (GPLv3)

SETLOCAL ENABLEDELAYEDEXPANSION
SET input="%~1"
SET vid="%~dpnx1"
SET output=%~dpn1
SET FILEPATH=%~dp1
:: Storing Paths

SET "filetype="
SET "scale="
SET "fps="
SET "mode="
SET "dither="
SET "bayerscale="
SET "start_time="
SET "duration="
SET "colormax="
SET "version="
SET "build="
:: Clearing all variables

SET WD=%TEMP%\GIFCONV
SET palette=%WD%\template
FOR /F "delims=" %%a in ('ffmpeg -version') DO (
	IF NOT DEFINED version (
		SET "version=%%a"
	) ELSE IF NOT DEFINED build (
		SET "build=%%a"
	)
)
GOTO :help_check_1
:: Setting the path to the Working Directory and storing FFmpeg Version String

:help_message
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [96mVideo to GIF/APNG converter v5.5 ^(C^) 2017-2022, MDHEXT ^&^ Nabi KaramAliZadeh ^<nabikaz@gmail.com^>[0m
ECHO [96mYou can download this fork from here: https://github.com/MDHEXT/video2gif[0m
ECHO [96myou can download the original release here: https://github.com/NabiKAZ/video2gif[0m
ECHO [96mThis tool uses ffmpeg, you can download that here: https://www.ffmpeg.org/download.html#build-windows[0m
ECHO [95mThis tool wouldn't be possible without the research listed here: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html[0m
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [32mUsage:[0m
ECHO gifconv [input_file] [Arguments]
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [32mArguments:[0m
ECHO	-t	: Specifies output filetype - 'gif' or 'apng'. [33mThe default is 'gif'.[0m
ECHO	-o	: Specifies output filename. [96m(will be outputted to the same directory as your input video file.)[0m
ECHO		  If left empty, [33mthis will default to the same filename as your video.[0m
ECHO	-r	: Specifies scale or size. The amount of pixels this value is set to will be the width of the gif.
ECHO		  [33mThe default is the same scale as the original video.[0m
ECHO	-f	: Specifies framerate in Hz. [33mThe default is 15.[0m
ECHO	-m	: Specifies one of the 3 modes listed below. [33mThe default is diff.[0m
ECHO	-d	: Specifies which dithering algorithm to be used. [33mThe default is Bayer.[0m
ECHO	-b	: Specifies the Bayer Scale. [31mThis can only be used when Bayer Dithering is applied.[0m See more 
ECHO		  information below. [96m(Optional)[0m
ECHO	-s	: Specifies the start of the gif file in HH:MM:SS.MS format. [96m(Optional)[0m
ECHO	-e	: Specifies the duration of the gif file in seconds. [96m(Optional)[0m
ECHO	-c	: Sets the maximum amount of colors useable per palette. [96m(Value up to 256)[0m [33mThis option isn't used
ECHO		  by default.[0m
ECHO	-k	: Enables error diffusion. [96m(Optional)[0m
ECHO	-p	: Opens the resulting GIF file in your default Photo Viewer. [96m(Optional)[0m
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [32mPalettegen Modes:[0m
ECHO 1: diff - only what moves affects the palette
ECHO 2: single - one palette per frame
ECHO 3: full - one palette for the whole gif
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [32mDithering Options:[0m
ECHO 1: Bayer
ECHO 2: Heckbert
ECHO 3: Floyd Steinberg
ECHO 4: Sierra2
ECHO 5: Sierra2_4a
ECHO 6: No Dithering
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [32mAbout Bayerscale:[0m
ECHO [31mWhen bayer dithering is selected[0m, the Bayer Scale option defines the scale of the pattern (how much the 
ECHO crosshatch pattern is visible). A low value means more visible pattern for less banding, and higher value
ECHO means less visible pattern at the cost of more banding. The option must be an integer value in the range
ECHO [0,5]. [33mThe Default is 2.[0m [96mBayer Scale is optional.[0m
ECHO ------------------------------------------------------------------------------------------------------------------------------------
ECHO [95mPeople who made this project come to fruition:[0m
ECHO ubitux, Nabi KaramAliZadeh, and the very kind and patient people in the Batch Discord Server.
ECHO Without these people's contributions, This script would not be possible. Thank you all for your contributions and assistence^^!
GOTO :EOF

:safchek
echo %filetype% | findstr /r "\<gif\> \<apng\>" >nul
IF %errorlevel% NEQ 0 (
	ECHO  [31mNot a valid file type[0m
	GOTO :EOF
)

IF %mode% GTR 3 (
	ECHO [31mNot a valid mode[0m
	GOTO :EOF
) ELSE IF %mode% LSS 1 (
	ECHO [31mNot a valid mode[0m
	GOTO :EOF
)
IF %dither% GTR 6 (
	ECHO [31mNot a valid dither algorithm[0m
	GOTO :EOF
) ELSE IF %dither% LSS 1 (
	ECHO [31mNot a valid dither algorithm[0m
	GOTO :EOF
)
IF DEFINED bayerscale (
	IF !bayerscale! GTR 5 (
		ECHO [31mNot a valid bayerscale value[0m
		GOTO :EOF
	) ELSE IF !bayerscale! LSS 1 (
		ECHO [31mNot a valid bayerscale value[0m
		GOTO :EOF
	)
	IF !bayerscale! LEQ 5 (
		IF %dither% EQU 1 GOTO :script_start
		IF %dither% NEQ 1 (
			ECHO [31mThis setting only works with bayer dithering[0m
			GOTO :EOF
		)
	)
)
GOTO :script_start
:: Setting a clear range of acceptable setting values and noob proofing bayerscale

:varin
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
	IF "%~1" =="-k" SET "errorswitch=0"
	IF "%~1" =="-p" SET "picswitch=0"
	SHIFT & GOTO :varin
)
GOTO :help_check_2
:: Using SHIFT command to go through the input and storing each setting into its own variable

:help_check_1
IF %input% == "" GOTO :help_message
IF %input% == "help" GOTO :help_message
IF %input% == "h" GOTO :help_message
IF %input% == "-h" GOTO :help_message
GOTO :varin
:: Checking for blank input or help commands

:help_check_2
IF NOT DEFINED filetype SET "filetype=gif"
IF NOT DEFINED scale SET "scale=-1"
IF NOT DEFINED fps SET fps=15
IF NOT DEFINED mode SET mode=1
IF NOT DEFINED dither SET dither=1
GOTO :safchek
:: Noob proofing the script to prevent it from breaking should critical settings not be defined

:script_start
IF "%filetype%"=="apng" SET output=%output%.png
IF "%filetype%"=="gif" SET output=%output%.gif
:: Set output file name

ECHO [33m%version%[0m
ECHO [33m%build%[0m
ECHO [32mOutput file: %output%[0m
ECHO [32mCreating Working Directory...[0m
MD "%WD%"
:: Displaying FFmpeg Version String and Creating the Working Directory

:palettegen
ECHO [32mGenerating Palette...[0m
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
:: Noob Proofing clipping

SET frames=%palette%_%%05d
SET filters=fps=%fps%,scale=%scale%:-1:flags=lanczos

IF %mode% EQU 1 SET encode=palettegen=stats_mode=diff
IF %mode% EQU 2 SET encode="palettegen=stats_mode=single"
IF %mode% EQU 3 SET encode=palettegen

IF DEFINED colormax (
	IF %mode% LEQ 2 SET "mcol=:max_colors=%colormax%"
	IF %mode% EQU 3 SET "mcol==max_colors=%colormax%"
)

ffmpeg -v warning %trim% -i %vid% -vf "%filters%,%encode%%mcol%" -y "%frames%.png"

IF NOT EXIST "%palette%_00001.png" (
	IF NOT EXIST "%palette%.png" (
		ECHO [31mFailed to generate palette file[0m
		GOTO :cleanup
	)
)
:: Putting together command to generate palette, executing it, and then checking if the file is in the Working Directory, if not, cleaning up working files

ECHO [32mEncoding Gif file...[0m
IF %mode% EQU 1 SET decode=paletteuse
IF %mode% EQU 2 SET "decode=paletteuse=new=1"
IF %mode% EQU 3 SET decode=paletteuse

IF DEFINED errorswitch (
	IF %mode% EQU 1 SET "errordiff==diff_mode=rectangle"
	IF %mode% EQU 2 SET "errordiff=:diff_mode=rectangle"
	IF %mode% EQU 3 SET "errordiff==diff_mode=rectangle"
)

IF %dither% EQU 1 SET ditheralg=bayer
IF %dither% EQU 2 SET ditheralg=heckbert
IF %dither% EQU 3 SET ditheralg=floyd_steinberg
IF %dither% EQU 4 SET ditheralg=sierra2
IF %dither% EQU 5 SET ditheralg=sierra2_4a
IF %dither% EQU 6 SET "ditheralg=none"

IF NOT %mode% EQU 2 (
	IF DEFINED errorswitch SET ditherenc=:dither=!ditheralg!
	IF NOT DEFINED errorswitch SET ditherenc==dither=!ditheralg!
)else SET ditherenc=:dither=!ditheralg!
:: Setting variables to put the command together; checking for Error Diffusion if using Bayer Scale and adjusting the command accordingly

IF NOT DEFINED bayerscale SET "bayer="
IF DEFINED bayerscale SET bayer=:bayer_scale=%bayerscale%
:: Checking for Bayer Scale and adjusting command

ffmpeg -v warning %trim% -i %vid% -thread_queue_size 512 -i "%frames%.png" -lavfi "%filters% [x]; [x][1:v] %decode%%errordiff%%ditherenc%%bayer%" -f %filetype% -plays 0 -y "%output%"

IF NOT EXIST "%output%" (
	ECHO [31mFailed to generate gif file[0m
	GOTO :cleanup
)
:: Checking if gif was created and cleaning up if not

IF DEFINED picswitch START "" "%output%"

:cleanup
ECHO [32mDeleting Temporary files...[0m
RMDIR /S /Q "%WD%"
ENDLOCAL
ECHO [93mDone![0m