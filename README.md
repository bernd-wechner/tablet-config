# tablet-config
A shell script to configure a graphics tablet attached to a Linux machine.

It should be internally self documenting.

In summary though it addresses the following problem under X windows currently when a graphics tablet is attached.

1. The tablet is attached with a USB line and a display line (VGA or DVI or HDMI or whatever).
1. The USB delivers the pen position (and related pen data)
1. The display is attached to a display port
1. Lacking a proprietary driver X has no way of knowing that the USB input relates to a particular display (though it could assume so) or which one if it does (the actual deeper problem).
1. When faced with multiple monitors (for example your existing monitor and the now added graphics tablet plugged into a display port) X defines a screen (call it the X screen) which is the bounding box of those monitors and provides some nice flexibility in terms of arranging them (via xrandr short for X Resize and Rotate) or depedning on you desktop through a GUI somehow. 
1. X manages the mapping between the X screen coordinate space and the indvidual monitor coordinates internally quite well.
1. But because X does not know which monitor if any is the graphics tablet (as some graphics tablets don't have a monitor), X maps the pen into the X screen space.
1. That sucks if you have a graphics tablet (with a monitor).
1. Alas the only ways around it are:
  1. a proprietary driver that knows about the ID info delivered by through USB and the display port and can associate the two, or
  1. you tell it manually what the association is.
1. The manual approach is described quite well here: https://wiki.archlinux.org/index.php/Calibrating_Touchscreen
1. The manual approach is a right royal pain.
1. This script makes it a little less painful, automating as much of it as possible in a shell script.

Good luck.
