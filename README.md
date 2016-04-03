# CarberryPI

## Initial setup
* Download a fresh copy of [Raspbian Jessie](https://www.raspberrypi.org/downloads/raspbian/) (Not lite)
* Write it to the sd card. Follow [these instructions](https://www.raspberrypi.org/documentation/installation/installing-images/README.md) if you are not sure how to do it.
* Put the sd card back to the PI, attach a keyboard, a mouse and a network cable and boot up the pi.
* Open up terminal, type: `sudo raspi-config`, and press enter.
* On raspi-config, do the following:
  * Expand Filesystem
  * (Optional) Change the password (default is `raspberry`)
  * Boot options -> Desktop Autologin
  * Wait for network at boot -> Fast boot without waiting for network connection
  * Internationalisation options -> Change timezone to your timezone
  * Advanced options
    * Overscan -> disable
    * (Optional) Hostname -> `carberrypi`
    * SSH -> Enable
    * Serial -> No
    * Audio -> Force 3.5mm ('headphone') jack
    * Update
* Exit raspi-config and reboot.

## VNC setup (optional)
* Follow these instructions: https://www.raspberrypi.org/documentation/remote-access/vnc/




To install, run:

`curl -o carpc-install.sh https://raw.githubusercontent.com/spawnedc/carpc/master/carpc-install.sh && sh carpc-install.sh`
