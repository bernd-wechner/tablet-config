#!/bin/bash
# This script is self documenting (use -h), or read below.
#
# First written in December 2015 by Bernd Wechner: https://github.com/bernd-wechner
#
# It should hopefully be redundant and superceded by improvments to Xorg on Linux
# within a year - go on, make it happen.

# Where the config is stored once it's specified
ConfigFile=~/.tablet-devices

#### Help
if [ "$1" = "--help"  ] || [ "$1" = "-h"  ] ; then
echo -e "Usage: tablet-config.sh [OPTION]
This script attempts to configure a graphics table for you.

It generates and applies a transformation matrix for the graphic table pen input such that it maps correctly to the graphics tablet.

For reasons we can only guess at, Linux supports graphic tablets reasonably well but the pen input arriving via USB is by default
mapped not onto the complete screen space which is the bounding box of all the monitors attached to your system. In the case of a
graphics tablet attached as a second display to a laptop or PC with an existing display this is the bounding box of the graphics
tablet display and the laptop or PC monitor. Let's call this bounding box the 'X screen' and the individual monitors/screens/displays
attached to your system 'display's ...

The problem is that the pen input arrives via USB and the graphics output goes out one of the display ports (VGA, DVI, HDMI or
whatever else your machine supports) and without a proprietary driver Linux does not know which display port is associated with
which USB input ... the connection is not self evident and made for us by proprietary drivers under MS-Windows.

So what we need to do is associate a pointer device (the graphics tablet pen) with a display device (the graphics tablet display),
and then inform Xorg with a transformation matrix that maps the X screen coordinates of the graphics table pen to the display
coordinates of the graphics tablet display. This is well documented here:

https://wiki.archlinux.org/index.php/Calibrating_Touchscreen

This script asks you on the first run to identify the graphics table pen and display from among the possibilities that Xorg reports
and remembers this so that on subsequent runs it doesn't need your help any more.

This script needs to be run any time you rearrange the relationship of your displays in the X screen space as this affects the
transform matrix. Sadly, at present this is a manual thing to do, but thanks to this script at least pretty easy.

This script genuinely hopes to become redundant in due course and see this done by default in Linux desktop systems.

Usage:
	-h --help         display this help
	-i --interactive  interactive mode, asks for the device names to use."
exit 0
fi

#### A simple function to select an item from an array
## Takes "${Array[@]}" as an argument
## Returns the slected index in $?
SelectFromMenu ()
{
  select option; do
    if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $(($#)) ];
    then
      return $[REPLY-1]
      break;
    else
      echo "Please select a number 1-$#"
    fi
  done
}

#### Configuration

# I'm not sure if there is ever more than one X Screen. If there is handling it will need some serious
# rework here in any case. The only scenario I have seen is xrandr reporting a single screen "Screen 0"
# This is centrally relevant to the work at hand as we need to map from the coordinate space of this screen
# to the coordinate space of the graphics tablet. We use its name to find its size from xrandr later. We
# could just as easily use the first line of xrandr output mind you.
Screen='Screen 0'

## Manual configuration (interactive)
if [[ ! -f "$ConfigFile" ]] || [[ "$1" = '-i' ]] || [[ "$1" = '--interactive' ]]; then
	readarray -t Pointers < <(xinput --list | egrep "slave\s+pointer" | sed -r -e "s/^[^[:alnum:]]*//" -e "s/\s*id=.*$//")
	readarray -t Monitors < <(xrandr | grep "connected" | sed -r "s/\s+(dis|)connected.*$//")

	echo "Please select the device that represents your graphics tablet pen. Its name should suggest it is a graphics tablet pen. If not we have a problem."
	SelectFromMenu "${Pointers[@]}"
	TabletInput=${Pointers[$?]}

	echo "Please select a device that represents your graphics tablet monitor. Its name should suggest which port you've plugged it into."
	SelectFromMenu "${Monitors[@]}"
	TabletOutput=${Monitors[$?]}

	echo -e "TabletInput=\"$TabletInput\"\nTabletOutput=\"$TabletOutput\"" > $ConfigFile

## Use default configuration (stored earlier)
else
	source $ConfigFile
fi

#### Calculate Transform Matrix
ScreenSize=$(xrandr | sed -n -e "/$Screen/ s/^.*current \(.*\),.*$/\1/p" | sed -r 's/\s*//g')
TabletSizeAndPos=$(xrandr | awk /$TabletOutput/ |  grep -oP '\d+x\d+\+\d+\+\d+')

# $ScreenSize $TabletSizeAndPos presents six numbers in order Xout, Yout, Xin, Yin, dXin, dYin
# The next contains the magic of calulcating a transform matrix from these six numbers that captures
# the size, rotation and placement of the graphics tablet in the screen space
# This well documented here: https://wiki.archlinux.org/index.php/Calibrating_Touchscreen
TransformMatrix=$(echo $ScreenSize $TabletSizeAndPos | sed -r -e 's/[x+]/ /g' | awk 'BEGIN { OFS=" "}; { print $3/$1,0,$5/$1,0,$4/$2,$6/$2,0,0,1 }')

#### Apply the Transform Matrix
TabletTransformBefore=$(xinput --list-props "$TabletInput" | awk -F "[ \t]*:[ \t]*" '/Coordinate Transformation Matrix/{print $2}')

xinput set-prop "$TabletInput" --type=float "Coordinate Transformation Matrix" $TransformMatrix

TabletTransformAfter=$(xinput --list-props "$TabletInput" | awk -F "[ \t]*:[ \t]*" '/Coordinate Transformation Matrix/{print $2}')

#### Summarize results
echo -e "Tablet Input Device:\t$TabletInput
Tablet Output Device:\t$TabletOutput
Screen:\t$Screen
Screen Size:\t$ScreenSize
Tablet Size and Position:\t$TabletSizeAndPos
Calculated Transform Matrix:\t$TransformMatrix
Transform Matrix before:\t$TabletTransformBefore
Transform Matrix after:\t$TabletTransformAfter" | expand -t 30
