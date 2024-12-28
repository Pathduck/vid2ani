#!/bin/bash

# Description: Video to GIF/APNG/WEBP converter
# By: MDHEXT, Nabi KaramAliZadeh, Pathduck
# Version: 6.0
# Url: https://github.com/Pathduck/vid2ani/ forked from https://github.com/MDHEXT/video2gif
# What this script is based on: http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
# License: GNU General Public License v3.0 (GPLv3)

# Function to print the help message
print_help() {
cat << EOF
${GREEN}Video to GIF/APNG/WEBP converter v6.0${OFF}
${BLUE}By MDHEXT, Nabi KaramAliZadeh, Pathduck${OFF}

${YELLOW}Usage: $0 [input] [Arguments]${OFF}

${YELLOW}Arguments:${OFF}
  -t  Output file type. Valid: 'gif' (default), 'png', 'webp'.
  -o  Output file. The default is the same name as the input video.
  -r  Scale or size. Width of the animation in pixels.
  -s  Start time of the animation (HH:MM:SS.MS).
  -e  End time of the animation (HH:MM:SS.MS).
  -f  Framerate in frames per second (default: 15).
  -d  Dithering algorithm to be used (default: 0).
  -b  Bayer Scale setting. Range 0 - 5, default is 2.
  -m  Palettegen mode: 1 (diff), 2 (single), 3 (full) (default: 1).
  -c  Maximum colors usable per palette. Range 3 - 256 (default).
  -k  Enables paletteuse error diffusion.
  -l  Enable lossy WebP compression and quality. Range 0 - 100.
  -v  Set FFmpeg log level (default: 'error').
  -p  Opens the resulting animation in the default viewer.
EOF
}


# Enable error handling
set -euo pipefail

# ANSI Colors
OFF=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 10)
YELLOW=$(tput setaf 11)
BLUE=$(tput setaf 12)

# Default values
fps=15
mode=1
dither=0
colormax=256
scale="-1"
filetype="gif"
loglevel="error"
bayerscale=""
start_time=""
end_time=""
trim=""
webp_lossy=""
errorswitch=""
errordiff=""
picswitch=""

# Check input
if [ $# -eq 0 ]; then print_help; exit; fi
input="$1"
output="${input%.*}"

echo "Input file: $input" 
echo "Output file: $output" 

# Parse Arguments
shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r) scale="$2"; shift 2;;
    -f) fps="$2"; shift 2;;
    -m) mode="$2"; shift 2;;
    -d) dither="$2"; shift 2;;
    -b) bayerscale="$2"; shift 2;;
    -t) filetype="$2"; shift 2;;
    -o) output="${2%.*}"; shift 2;;
    -s) start_time="$2"; shift 2;;
    -e) end_time="$2"; shift 2;;
    -c) colormax="$2"; shift 2;;
    -l) webp_lossy="$2"; shift 2;;
    -v) loglevel="$2"; shift 2;;
    -k) errorswitch=1; shift;;
    -p) picswitch=1; shift;;
    -h|--help) print_help; exit;;
    *) echo ${RED}"Unknown option $1"${OFF}; exit 1;;
  esac
done

# Input validation
if [[ -z "$input" ]]; then
  echo "Input file is required."; print_help; exit 1
fi

# Fix paths for Cygwin and create working dir
if [[ "$(uname -o)" == "Cygwin" ]]; then
  # Use Windows-compatible directories for Cygwin
	input=$(cygpath -w "$input")
	output=$(cygpath -w "$output")
  WD=$(cygpath -w "$(mktemp -d -t vid2ani-XXXXXX)")
else
  # Use POSIX-compatible directories
  WD=$(mktemp -d -t vid2ani-XXXXXX)
fi

echo "Input file: $input" 
echo "Output file: $output" 

# Cleanup on exit, interrupt, termination
trap 'rm -rf "$WD"' EXIT INT TERM

# Validate output file extension
case "$filetype" in
  gif) output="$output.gif";;
  png) output="$output.png"; filetype="apng";;
  apng) output="$output.png";;
  webp) output="$output.webp";;
  *) echo ${RED}"Invalid file type: $filetype"${OFF}; exit 1;;
esac

# Validate Palettegen
if [[ "$mode" -lt 1 || "$mode" -gt 3 ]]; then
	echo ${RED}"Not a valid palettegen mode"${OFF}; exit 1;
fi

# Validate Dithering
if [[ "$dither" -gt 8 || "$dither" -lt 0 ]]; then
	echo ${RED}"Not a valid dither algorithm"${OFF}; exit 1;
fi

# Validate Bayerscale
if [[ -n "$bayerscale" ]]; then
	if [[ "$bayerscale" -gt 5 || "$bayerscale" -lt 0 ]]; then
		echo ${RED}"Not a valid bayerscale value"${OFF}; exit 1;
	fi
	if [[ "$dither" -ne 1 ]]; then
		echo ${RED}"This setting only works with bayer dithering"${OFF}; exit 1;
	fi
fi

# Validate Lossy WEBP
if [[ -n "$webp_lossy" ]]; then
	if [[ "$filetype" != "webp" ]]; then
		echo ${RED}"Lossy is only valid for filetype webp"${OFF}; exit 1;
	fi
  if [[ "$webp_lossy" -gt 100 || "$webp_lossy" -lt 0 ]]; then
		echo ${RED}"Not a valid lossy quality value"${OFF}; exit 1;
	fi
fi

# Validate Clipping
if [[ -n "$start_time" ]]; then
  if [[ -z "$end_time" ]]; then
    echo ${RED}"End time (-e) is required when start time (-s) is specified."${OFF}; exit 1;
  fi
	trim="-ss $start_time -to $end_time"
fi

# Validate Framerate
if [[ "$fps" -le 0 ]]; then
  echo ${RED}"Framerate (-f) must be greater than 0."${OFF}; exit 1;
fi

# Validate Max Colors
if [[ "$colormax" -lt 3 || "$colormax" -gt 256 ]]; then
  echo ${RED}"Max colors (-c) must be between 3 and 256."${OFF}; exit 1;
fi

# Displaying FFmpeg version string
ffmpeg_version=$(ffmpeg -version | head -n2)
echo ${YELLOW}"$ffmpeg_version"${OFF}
echo ${GREEN}Output file:${OFF} $output

## Putting together command to generate palette ##
palette="$WD/palette.png"
filters="fps=$fps,scale=$scale:-1:flags=lanczos"

# Palettegen mode
encode=""
if [[ -n "$mode" ]]; then
	case "$mode" in
		1) encode="palettegen=stats_mode=diff";;
		2) encode="palettegen=stats_mode=single";;
		3) encode="palettegen";;
		*) echo ${RED}"Invalid palettegen mode"${OFF}; exit 1;;
	esac
fi 

# Max colors
mcol=""
if [[ -n "$colormax" ]]; then
  if [[ "$mode" -le 2 ]]; then mcol=":max_colors=${colormax}"; fi
  if [[ "$mode" -eq 3 ]]; then mcol="=max_colors=${colormax}"; fi
fi

# Generate palette
echo ${GREEN}"Generating palette..."${OFF}
echo "Palette file: $palette"
ffmpeg -v "${loglevel}" ${trim:-} -i "${input}" -vf "${filters},${encode}${mcol}" -y "${palette}"

if [[ ! -f "$palette" ]]; then
  echo ${RED}"Palette generation failed: $palette not found."${OFF}; exit 1
fi

## Setting variables to put the encode command together ##

# Checking for Error Diffusion if using Bayer Scale and adjusting the command accordingly
if [[ -n "$mode" ]]; then
	case "$mode" in
		1) decode="paletteuse";;
		2) decode="paletteuse=new=1";;
		3) decode="paletteuse";;
		*) echo ${RED}"Invalid palettegen mode"${OFF}; exit 1;;
	esac
fi 

# Error diffusion
if [[ -n "$errorswitch" ]]; then
	case "$mode" in
		1) errordiff="=diff_mode=rectangle";;
		2) errordiff=":diff_mode=rectangle";;
		3) errordiff="=diff_mode=rectangle";;
		*) echo ${RED}"Invalid palettegen mode"${OFF}; exit 1;;
	esac
fi 

# WEBP pixel format and lossy quality
if [[ "$filetype" == "webp" && -n "$webp_lossy" ]]; then
  webp_lossy="-lossless 0 -pix_fmt yuva420p -quality $webp_lossy"
fi

# Prepare dithering and encoding options
ditheralg="none"
case "$dither" in
  0) ditheralg="none";;
  1) ditheralg="bayer";;
  2) ditheralg="heckbert";;
  3) ditheralg="floyd_steinberg";;
  4) ditheralg="sierra2";;
  5) ditheralg="sierra2_4a";;
  6) ditheralg="sierra3";;
  7) ditheralg="burkes";;
  8) ditheralg="atkinson";;
  *) echo ${RED}"Invalid dither mode: $dither"${OFF}; exit 1;;
esac

# Paletteuse error diffusion
if [[ "$mode" -ne 2 ]]; then
	if [[ -n "$errorswitch" ]]; then ditherenc=":dither=$ditheralg"; fi
	if [[ -z "$errorswitch" ]]; then ditherenc="=dither=$ditheralg"; fi
else
	ditherenc=":dither=$ditheralg"
fi

# Checking for Bayer Scale and adjusting command
if [[ -z "$bayerscale" ]]; then bayer=""; fi
if [[ -n "$bayerscale" ]]; then bayer=":bayer_scale=$bayerscale"; fi

# Encode animation
echo ${GREEN}"Encoding animation..."${OFF}
ffmpeg -v "${loglevel}" ${trim:-} -i "${input}" -thread_queue_size 512 -i "${palette}" -lavfi "${filters} [x]; [x][1:v] ${decode}${errordiff}${ditherenc}${bayer}" -f "${filetype}" ${webp_lossy:-} -loop 0 -plays 0 -y "${output}"

if [[ ! -f "$output" ]]; then
  echo ${RED}"Failed to generate animation."${OFF}; exit 1
fi

# Open output if picswitch is enabled
if [[ -n "$picswitch" ]]; then
  xdg-open "$output"
fi

echo ${YELLOW}"Done."${OFF}
