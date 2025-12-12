#!/bin/bash
# Author: Wig Cheng <onlywig@gmail.com>
# Date: 12/11/2024

PLATFORM=$1
DISTRO=$2
LANGUAGE=$3

COL_GREEN="\e[1;32m"
COL_NORMAL="\e[m"

echo "${COL_GREEN}customized minimal rootfs staring...${COL_NORMAL}"
echo "${COL_GREEN}creating ubuntu sudoer account...${COL_NORMAL}"
cd /
echo $PLATFORM > /etc/hostname
echo -e "127.0.1.1\t $PLATFORM" >> /etc/hosts
echo -e "nameserver\t8.8.8.8" >> /etc/resolv.conf
echo -e "nameserver\t8.8.4.4" >> /etc/resolv.conf

(echo "root"; echo "root";) | passwd
(echo "ubuntu"; echo "ubuntu"; echo;) | adduser ubuntu
usermod -aG sudo ubuntu

echo "${COL_GREEN}apt-get server upgrading...${COL_NORMAL}"

touch /etc/apt/sources.list
# apt-get source adding
cat <<END > /etc/apt/sources.list
deb http://ports.ubuntu.com/ubuntu-ports/ $DISTRO main
deb http://ports.ubuntu.com/ubuntu-ports/ $DISTRO universe
deb http://ports.ubuntu.com/ubuntu-ports/ $DISTRO multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ $DISTRO-backports main
deb http://ports.ubuntu.com/ubuntu-ports/ $DISTRO-security main
END


# apt-get source update and installation
apt -y update
apt -y full-upgrade && apt -y autoclean && apt -y autoremove
apt -y install openssh-server iw wpasupplicant hostapd util-linux procps iproute2 haveged dnsmasq iptables net-tools ppp ntp ntpdate bridge-utils can-utils v4l-utils usbutils
apt -y install bash-completion ifupdown resolvconf alsa-utils gpiod cloud-utils udhcpc feh modemmanager software-properties-common bluez blueman gpiod

# for teamviewer and anydesk
apt -y install libpolkit-gobject-1-0:armhf libraspberrypi0:armhf libraspberrypi-dev:armhf libraspberrypi-bin:armhf libgles-dev:armhf libegl-dev:armhf
apt -y install libegl1-mesa libgail-common libgail18 libgtk2.0-0 libgtk2.0-bin libgtk2.0-common libpango1.0-0

# chromium-browser
add-apt-repository ppa:xtradeb/apps -y
apt -y install chromium

# ensure LXQt can start correctly after relogin
echo 'export XDG_RUNTIME_DIR=/run/user/$(id -u)' >> /home/ubuntu/.profile
chown ubuntu:ubuntu /home/ubuntu/.profile

# for multiple languages
apt -y install language-selector-gnome
if [[ "$LANGUAGE" == "zh-hant" ]]; then
	apt -y install language-pack-zh-hant language-pack-gnome-zh-hant fonts-noto-cjk
	locale-gen zh_TW.UTF-8
	update-locale LANG=zh_TW.UTF-8
elif [[ "$LANGUAGE" == "japanese" ]]; then
	apt -y install language-pack-ja language-pack-gnome-ja fonts-noto-cjk fonts-takao
	locale-gen ja_JP.UTF-8
	update-locale LANG=ja_JP.UTF-8
	style_file="/usr/share/fluxbox/styles/ubuntu-light"
	if [ -f "$style_file" ]; then
		sed -i 's/^menu.frame.font:.*/menu.frame.font: Noto Sans CJK JP-10:bold/' "$style_file"
		sed -i 's/^menu.title.font:.*/menu.title.font: Noto Sans CJK JP-12:bold/' "$style_file"
		sed -i 's/^toolbar.clock.font:.*/toolbar.clock.font: Noto Sans CJK JP-10:bold/' "$style_file"
		sed -i 's/^toolbar.workspace.font:.*/toolbar.workspace.font: Noto Sans CJK JP-12:bold/' "$style_file"
		sed -i 's/^toolbar.iconbar.focused.font:.*/toolbar.iconbar.focused.font: Noto Sans CJK JP-10:bold/' "$style_file"
		sed -i 's/^toolbar.iconbar.unfocused.font:.*/toolbar.iconbar.unfocused.font: Noto Sans CJK JP-10/' "$style_file"
		sed -i 's/^window.font:.*/window.font: Noto Sans CJK JP-10:bold/' "$style_file"
	fi
elif [[ "$LANGUAGE" == "korean" ]]; then
    apt -y install language-pack-ko language-pack-gnome-ko fonts-noto-cjk fonts-unfonts-core
    locale-gen ko_KR.UTF-8
    update-locale LANG=ko_KR.UTF-8
fi

# enable required repositories for ROS2
apt -y install software-properties-common
add-apt-repository -y universe
apt -y update
apt -y install curl
export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
dpkg -i /tmp/ros2-apt-source.deb
apt -y update
apt -y upgrade
apt -y install ros-rolling-ros-base

# for build ROS2
apt -y install colcon

# make sure no other display managers are installed or left behind
apt -y purge sddm gdm3 lightdm || true

# X11 setting
cat <<END > /etc/X11/xorg.conf
Section "Device"
Identifier  "Framebuffer Device"
Driver      "fbdev"
Option      "fbdev"   "/dev/fb0"
EndSection

Section "Screen"
Identifier "Screen0"
Device     "Framebuffer Device"
EndSection
END

# audio setting
cat <<END > /home/ubuntu/.asoundrc
pcm.!default {
  type plug
  slave {
    pcm "hw:0,0"
  }
}

ctl.!default {
  type hw
  card 0
}
END

# GUI desktop support
if [[ "$DISTRO" == "jammy" ]]; then
    apt -y install xfce4
elif [[ "$DISTRO" == "noble" ]]; then
    apt -y install lxqt
fi

apt -y install fluxbox onboard xterm xfce4-screenshooter rfkill alsa-utils minicom strace
apt-get update && echo "slim shared/default-x-display-manager select slim" | debconf-set-selections && DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -y install slim && echo "/usr/bin/slim" | tee /etc/X11/default-display-manager
# auto login
sed -i 's/#auto_login\s\+no/auto_login          yes/' /etc/slim.conf
sed -i 's/#default_user\s\+simone/default_user        ubuntu/' /etc/slim.conf

wget https://ubuntucommunity.s3.us-east-2.amazonaws.com/original/3X/6/3/63c50fde4f2fe64d161e43f4d7588049a208b524.jpeg
mv 63c50fde4f2fe64d161e43f4d7588049a208b524.jpeg /home/ubuntu/wallpaper.jpeg

rm -rf /usr/share/xsessions/fluxbox.desktop

# Install ubuntu-restricted-extras
echo steam steam/license note '' | sudo debconf-set-selections
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections # auto accepted eula agreements
apt -y install ttf-mscorefonts-installer
echo ubuntu-restricted-extras msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections # auto accepted eula agreements
apt -y install ubuntu-restricted-extras

apt -y remove xfce4-screensaver xscreensaver gnome-terminal
apt -y autoremove

mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/
chown ubuntu:ubuntu /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/
chown ubuntu:ubuntu /home/ubuntu/.config/xfce4/xfconf/
chown ubuntu:ubuntu /home/ubuntu/.config/xfce4/
chown ubuntu:ubuntu /home/ubuntu/.config/
touch /home/ubuntu/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cat <<END > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="empty"/>
    <property name="IconThemeName" type="empty"/>
    <property name="DoubleClickTime" type="empty"/>
    <property name="DoubleClickDistance" type="empty"/>
    <property name="DndDragThreshold" type="empty"/>
    <property name="CursorBlink" type="empty"/>
    <property name="CursorBlinkTime" type="empty"/>
    <property name="SoundThemeName" type="empty"/>
    <property name="EnableEventSounds" type="empty"/>
    <property name="EnableInputFeedbackSounds" type="empty"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="empty"/>
    <property name="Antialias" type="empty"/>
    <property name="Hinting" type="empty"/>
    <property name="HintStyle" type="empty"/>
    <property name="RGBA" type="empty"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CanChangeAccels" type="empty"/>
    <property name="ColorPalette" type="empty"/>
    <property name="FontName" type="string" value="Sans 15"/>
    <property name="MonospaceFontName" type="empty"/>
    <property name="IconSizes" type="empty"/>
    <property name="KeyThemeName" type="empty"/>
    <property name="ToolbarStyle" type="empty"/>
    <property name="ToolbarIconSize" type="empty"/>
    <property name="MenuImages" type="empty"/>
    <property name="ButtonImages" type="empty"/>
    <property name="MenuBarAccel" type="empty"/>
    <property name="CursorThemeName" type="empty"/>
    <property name="CursorThemeSize" type="empty"/>
    <property name="DecorationLayout" type="empty"/>
  </property>
</channel>
END

yes "Y" | apt install --reinstall network-manager-gnome

# let network-manager handle all network interfaces
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

# disable type password everytime using ubuntu user
sed -i 's/sudo\tALL=(ALL:ALL) ALL/sudo\tALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

# zram swap size
echo "${COL_GREEN}Add swap partition...Default size is one-fourth of total memory${COL_NORMAL}"
apt -y install zram-config
sed -i 's/totalmem\ \/\ 2/totalmem\ \/\ 4/' /usr/bin/init-zram-swapping

mkdir -p /lib/modules/

# clear the patches
rm -rf /var/cache/apt/archives/*
sync
