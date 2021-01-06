#!/usr/bin/env bash

# Run using ./splice-wallpaper.sh photo.png
# And it will split the wallpaper for all monitors and
# Apply them through KDE, makes tripple monitor setups a bit easier

# Check for tools
[ ${BASH_VERSINFO[0]} -lt 4 ] && { echo "ERROR: bash version 4 or higher is required." >&2; exit 2; }
xrandr --help &>/dev/null || { echo "ERROR: Missing xrandr. Install xserver utils." >&2; exit 2; }
tail --version &>/dev/null || { echo "ERROR: Missing tail. Install coreutils." >&2; exit 2; }
convert -version &>/dev/null || { echo "ERROR: Missing convert. Install imagemagick." >&2; exit 2; }

# Check input file
[ -r "${1}" ] && convert "${1}" info: &>/dev/null || { echo "ERROR: Supplied argument '${1}' was not found or is in unknown image format."; exit 3; }

declare -a NAME WIDTH HEIGHT OFFSETX OFFSETY
declare MINX=65535 MINY=65535 MAXX=0 MAXY=0

while read ID N1 RES N; do

  W=$(( ${RES%%/*} ))

  H="${RES#*x}"
  H=$(( ${H%%/*} ))

  X="${RES#*+}"
  Y=$(( ${X#*+} ))
  X=$(( ${X%%+*} ))

  ID=$(( ${ID%:} ))

# echo "Screen ${ID} '${N}' ${W}x${H} at ${X},${Y}"

  NAME[${ID}]="${N//[^A-Za-z0-9-]/_}"
  WIDTH[${ID}]="${W}"
  HEIGHT[${ID}]="${H}"
  OFFSETX[${ID}]="${X}"
  OFFSETY[${ID}]="${Y}"
  [ ${MINX} -gt ${X} ] && MINX=${X}
  [ ${MINY} -gt ${Y} ] && MINY=${Y}
  [ ${MAXX} -lt $(( X+W )) ] && MAXX=$(( X+W ))
  [ ${MAXY} -lt $(( Y+H )) ] && MAXY=$(( Y+H ))

done <<<"$(xrandr --listactivemonitors|tail -n +2)"

for I in ${!NAME[@]}; do
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var allDesktops = desktops();print (allDesktops); d = allDesktops[${I}];d.wallpaperPlugin = \"org.kde.image\";d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");d.writeConfig(\"Image\", \"file:///${PWD}/${1%.*}_${I}_${NAME[$I]}.${1##*.}\")"
  convert "${1}" -filter Cubic -resize $((MAXX-MINX))x$((MAXY-MINY))\! -crop ${WIDTH[$I]}x${HEIGHT[$I]}+${OFFSETX[$I]}+${OFFSETY[$I]} +repage "${1%.*}_${I}_${NAME[$I]}.${1##*.}"
done
