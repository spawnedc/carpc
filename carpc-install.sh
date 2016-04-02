#!/bin/bash

# free some space
sudo apt-get --yes --force-yes remove --purge minecraft-pi scratch wolfram-engine debian-reference-* epiphany-browser* sonic-pi supercollider*

# navit dev
sudo apt-get --yes install git imagemagick libdbus-1-dev libdbus-glib-1-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libimlib2-dev librsvg2-bin libspeechd-dev libxml2-dev ttf-liberation libgtk2.0-dev gcc g++ cmake make zlib1g-dev libpng12-dev libsdl-image1.2-dev libdevil-dev libglc-dev freeglut3-dev libxmu-dev libgps-dev

# install Kodi dependencies
sudo apt-get --yes --force-yes install libssh-4 libmicrohttpd10 libtinyxml2.6.2 libyajl2 libmysqlclient18 liblzo2-2 libpcrecpp0 libmysqlclient-dev

# Kodi dev
sudo apt-get --yes install libboost1.50-all swig curl libgnutls-dev libxslt1-dev libmpeg2-4-dev libmad0-dev libjpeg8-dev libsamplerate0-dev libogg-dev libvorbis-dev libflac-dev libtiff4-dev liblzo2-dev zip unzip libsqlite3-dev libpcre3-dev libjasper-dev libsdl1.2-dev libass-dev libmodplug-dev libcdio-dev libtinyxml2-dev libyajl-dev libgpg-error-dev libgcrypt11-dev libmicrohttpd-dev autoconf libtool autopoint libudev-dev python-dev python-imaging libcurl4-gnutls-dev libbz2-dev libtinyxml-dev libssh-dev libxrandr-dev libsmbclient-dev libcap-dev gawk gperf debhelper libiso9660-dev liblockdev1-dev ccache gcc-4.8 g++-4.8 libparted-dev

# Send click events to X windows
sudo apt-get --yes --force-yes install xdotool

# gpsd and tools
sudo apt-get --yes --force-yes install gpsd gpsd-clients

# espeak
sudo apt-get --yes --force-yes install espeak

# Download and build Navit
cd ~
git clone https://github.com/navit-gps/navit.git
mkdir navit-build && cd navit-build
cmake -DFREETYPE_INCLUDE_DIRS=/usr/include/freetype2/ --enable-map-csv ~/navit
make -j4

# Install wiringPI
cd ~
git clone git://git.drogon.net/wiringPi
cd wiringPi
git pull origin
./build

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

FROM="cp -r ${PWD}/$UPDATE_DIR/"
FROM_SU="sudo ${FROM}"
TO="/"
CARPC="/opt/carpc/"

#############################################################
# Unpack archive
#############################################################
sudo killall -9 kodi.bin
sudo killall -9 navit
sudo mkdir ${CARPC}
sudo chmod -R a+rwx ${CARPC}

echo -e "\e[1;32mDownloading archive\e[0m"
wget https://drive.google.com/uc?export=download&id=0B5rjBYR8_iWJZ2FDT2p5LVV2c2s -O ${PWD}/$UPDATE_DIR.zip

echo -e "\e[1;32mUnpacking archive\e[0m"
unzip -zxf ${PWD}/$UPDATE_DIR.zip
rm ${PWD}/$UPDATE_DIR.zip


#############################################################
# System
#############################################################
# Kernel
echo -e "\e[1;32mKernel\e[0m"
sudo rm -rf /boot/kernel7.img
sudo rm -rf /lib/firmware/
sudo rm -rf /lib/modules/
mkdir -p $TO/boot/
mkdir -p $TO/lib/
$FROM_SU/lib/modules/ $TO/lib/
$FROM_SU/lib/firmware/ $TO/lib/
$FROM_SU/boot/kernel7.img $TO/boot/

# Autostart KODI
$FROM_SU/etc/inittab $TO/etc/
$FROM_SU/etc/profile $TO/etc/
$FROM_SU/etc/modprobe.d/raspi-blacklist.conf $TO/etc/modprobe.d/

#############################################################
# KODI
#############################################################
echo -e "\e[1;32mKODI core\e[0m"
# Create local directories
mkdir -p $TO/usr/local/include/
mkdir -p $TO/usr/local/lib/
mkdir -p $TO/usr/local/share/

# Copy Kodi new files
$FROM_SU/usr/local/include/libcec/ $TO/usr/local/include/
$FROM_SU/usr/local/include/shairport/ $TO/usr/local/include/
$FROM_SU/usr/local/include/taglib/ $TO/usr/local/include/
$FROM_SU/usr/local/include/kodi $TO/usr/local/include/
$FROM_SU/usr/local/lib/kodi/ $TO/usr/local/lib/
$FROM_SU/usr/local/lib/libcec* $TO/usr/local/lib/
$FROM_SU/usr/local/lib/libshair* $TO/usr/local/lib/
$FROM_SU/usr/local/lib/libtag* $TO/usr/local/lib/
$FROM_SU/usr/local/share/kodi/ $TO/usr/local/share/

sudo rm /usr/local/lib/libshairport.so.0
sudo ln -s /usr/local/lib/libshairport.so /usr/local/lib/libshairport.so.0
sudo rm /usr/local/lib/libcec.so.2
sudo ln -s /usr/local/lib/libcec.so /usr/local/lib/libcec.so.2

# KODI Addons
echo -e "\e[1;32mKODI Addons\e[0m"
mkdir -p $TO/home/pi/.kodi/
$FROM/home/pi/.kodi/addons $TO/home/pi/.kodi/

#############################################################
# Navit
#############################################################
echo -e "\e[1;32mNavit\e[0m"
mkdir -p $TO/home/pi/.navit/xml/skins
$FROM/${CARPC}/navit $TO/${CARPC}/
$FROM/home/pi/.navit/ $TO/home/pi/
echo -e "\e[1;32mDownloading map\e[0m"
wget http://maps9.navit-project.org/api/map/?bbox=-9.7,49.6,2.2,61.2 -O $TO/home/pi/.navit/map1.bin

#############################################################
# Binaries: carpc-controller, set_date
#############################################################
echo -e "\e[1;32mBinaries\e[0m"
mkdir -p $TO/usr/bin/
$FROM_SU/usr/bin/carpc-setdate $TO/usr/bin/

#############################################################
# Tools
#############################################################
echo -e "\e[1;32mTools\e[0m"
mkdir -p $TO/${CARPC}
$FROM/${CARPC}/tools $TO/${CARPC}/

#############################################################
# Startup
#############################################################
mkdir -p $TO/${CARPC}/startup/
$FROM/${CARPC}/startup/StartCarPC $TO/${CARPC}/startup/StartCarPC
$FROM/${CARPC}/startup/StartCarPC_stage2 $TO/${CARPC}/startup/StartCarPC_stage2

#############################################################
# Sources
#############################################################
echo -e "\e[1;32mSources\e[0m"
mkdir -p $TO/${CARPC}/
$FROM/${CARPC}/src/ $TO/${CARPC}

cp -f $UPDATE_DIR/version /${CARPC}/.carpc.version

sync
echo -e "\e[1;32mDone\e[0m"
