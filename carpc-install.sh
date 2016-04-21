#!/bin/bash

HOME="/home/pi"
SOURCES_DIR="${HOME}/src"
NAVIT_BUILD_DIR="${SOURCES_DIR}/navit-build"
WIRINGPI_BUILD_DIR="${SOURCES_DIR}/wiringPi"

if [ ! -d "$SOURCES_DIR" ]; then
  mkdir ${SOURCES_DIR}
fi

# free some space
sudo apt-get --yes --force-yes remove --purge minecraft-pi scratch wolfram-engine debian-reference-* epiphany-browser* sonic-pi supercollider*

# install Kodi dependencies
sudo apt-get --yes --force-yes install libssh-4 libmicrohttpd10 libtinyxml2.6.2 libyajl2 libmysqlclient18 liblzo2-2 libpcrecpp0 libmysqlclient-dev

# Jessie issues
wget http://ftp.uk.debian.org/debian/pool/main/libg/libgcrypt11/libgcrypt11_1.5.0-5+deb7u3_armhf.deb
sudo dpkg -i libgcrypt11_1.5.0-5+deb7u3_armhf.deb
sudo apt-get --yes install libtasn1-3
wget http://ftp.uk.debian.org/debian/pool/main/g/gnutls26/libgnutls26_2.12.20-8+deb7u3_armhf.deb
sudo dpkg -i libgnutls26_2.12.20-8+deb7u3_armhf.deb

rm libgcrypt11_1.5.0-5+deb7u3_armhf.deb
rm libgnutls26_2.12.20-8+deb7u3_armhf.deb

# Send click events to X windows
sudo apt-get --yes --force-yes install xdotool

# gpsd and tools
sudo apt-get --yes --force-yes install gpsd gpsd-clients

# espeak
sudo apt-get --yes --force-yes install espeak

# Download and build Navit
if [ ! -d "$NAVIT_BUILD_DIR" ]; then
  # navit dev
  sudo apt-get --yes install git imagemagick libdbus-1-dev libdbus-glib-1-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libimlib2-dev librsvg2-bin libspeechd-dev libxml2-dev ttf-liberation libgtk2.0-dev gcc g++ cmake make zlib1g-dev libpng12-dev libsdl-image1.2-dev libdevil-dev libglc-dev freeglut3-dev libxmu-dev libgps-dev

  cd ${SOURCES_DIR}
  git clone https://github.com/navit-gps/navit.git
  mkdir ${NAVIT_BUILD_DIR}
  cd ${NAVIT_BUILD_DIR}
  cmake -DFREETYPE_INCLUDE_DIRS=/usr/include/freetype2/ --enable-map-csv ${SOURCES_DIR}/navit
  make -j4
fi
#
# # Install wiringPI
# if [ ! -d "$WIRINGPI_BUILD_DIR" ]; then
#   cd ${SOURCES_DIR}
#   git clone git://git.drogon.net/wiringPi
#   cd ${WIRINGPI_BUILD_DIR}
#   git pull origin
#   ./build
# fi

# Cleanup
sudo apt-get --yes autoremove
sudo apt-get --yes autoclean

# Create system variable
echo "export CARPC_PATH=/opt/carpc/" >> ~/.bashrc
source ~/.bashrc

######################################################
# Install
######################################################
UPDATE_DIR="rpi-carpc-update"

FROM="cp -r ${PWD}/$UPDATE_DIR"
FROM_SU="sudo ${FROM}"
CARPC="/opt/carpc"

#############################################################
# Unpack archive
#############################################################
sudo killall -9 kodi.bin
sudo killall -9 navit
sudo mkdir ${CARPC}
sudo chmod -R a+rwx ${CARPC}

echo -e "\e[1;32mDownloading archive\e[0m"
wget https://googledrive.com/host/0B5rjBYR8_iWJR2wyR2Y5X3lnaFU/rpi-carpc-update.zip -O ${PWD}/$UPDATE_DIR.zip

echo -e "\e[1;32mUnpacking archive\e[0m"
unzip ${PWD}/$UPDATE_DIR.zip
rm ${PWD}/$UPDATE_DIR.zip

#############################################################
# System
#############################################################
# Kernel
echo -e "\e[1;32mKernel\e[0m"
sudo rm -rf /boot/kernel7.img
sudo rm -rf /lib/firmware/
sudo rm -rf /lib/modules/
mkdir -p /boot/
mkdir -p /lib/
$FROM_SU/lib/modules/ /lib/
$FROM_SU/lib/firmware/ /lib/
$FROM_SU/boot/kernel7.img /boot/

# Autostart KODI
$FROM_SU/etc/inittab /etc/
$FROM_SU/etc/profile /etc/
$FROM_SU/etc/modprobe.d/raspi-blacklist.conf /etc/modprobe.d/

#############################################################
# KODI
#############################################################
echo -e "\e[1;32mKODI core\e[0m"
# Create local directories
mkdir -p /usr/local/include/
mkdir -p /usr/local/lib/
mkdir -p /usr/local/share/

# Copy Kodi new files
$FROM_SU/usr/local/include/libcec/ /usr/local/include/
$FROM_SU/usr/local/include/shairport/ /usr/local/include/
$FROM_SU/usr/local/include/taglib/ /usr/local/include/
$FROM_SU/usr/local/include/kodi /usr/local/include/
$FROM_SU/usr/local/lib/kodi/ /usr/local/lib/
$FROM_SU/usr/local/lib/libcec* /usr/local/lib/
$FROM_SU/usr/local/lib/libshair* /usr/local/lib/
$FROM_SU/usr/local/lib/libtag* /usr/local/lib/
$FROM_SU/usr/local/share/kodi/ /usr/local/share/

sudo rm /usr/local/lib/libshairport.so.0
sudo ln -s /usr/local/lib/libshairport.so /usr/local/lib/libshairport.so.0
sudo rm /usr/local/lib/libcec.so.2
sudo ln -s /usr/local/lib/libcec.so /usr/local/lib/libcec.so.2

# CarPC autostart
mkdir -p /home/pi/.config
mkdir -p /home/pi/.config/lxsession
mkdir -p /home/pi/.config/lxsession/LXDE-pi
$FROM/home/pi/.config/lxsession/LXDE-pi/autostart /home/pi/.config/lxsession/LXDE-pi

# KODI Addons
echo -e "\e[1;32mKODI Addons\e[0m"
mkdir -p /home/pi/.kodi/
$FROM/home/pi/.kodi/addons /home/pi/.kodi/

#############################################################
# Navit
#############################################################
echo -e "\e[1;32mNavit\e[0m"
mkdir -p /home/pi/.navit/xml/skins
${NAVIT_BUILD_DIR}/navit ${CARPC}
$FROM/home/pi/.navit/ /home/pi/
mv ${CARPC}/navit/navit.xml ${CARPC}/navit/navit.xml.orig
ln -s ${HOME}/.navit/navit.xml ${CARPC}/navit/
if [ ! -f "/home/pi/.navit/map1.bin" ]; then
  echo -e "\e[1;32mDownloading map\e[0m"
  wget http://maps9.navit-project.org/api/map/?bbox=-9.7,49.6,2.2,61.2 -O /home/pi/.navit/map1.bin
fi

#############################################################
# Binaries: carpc-controller, set_date
#############################################################
echo -e "\e[1;32mBinaries\e[0m"
mkdir -p /usr/bin/
$FROM_SU/usr/bin/carpc-setdate /usr/bin/

#############################################################
# Tools
#############################################################
echo -e "\e[1;32mTools\e[0m"
mkdir -p /${CARPC}
$FROM/${CARPC}/tools /${CARPC}/

#############################################################
# Startup
#############################################################
mkdir -p /${CARPC}/startup/
$FROM/${CARPC}/startup/StartCarPC /${CARPC}/startup/StartCarPC
$FROM/${CARPC}/startup/StartCarPC_stage2 /${CARPC}/startup/StartCarPC_stage2

cp -f $UPDATE_DIR/version /${CARPC}/.carpc.version

sync
echo -e "\e[1;32mDone\e[0m"
