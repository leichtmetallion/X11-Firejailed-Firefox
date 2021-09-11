#!/bin/bash

#
# https://wiki.gentoo.org/wiki/User:Sakaki/Sakaki%27s_EFI_Install_Guide/Sandboxing_the_Firefox_Browser_with_Firejail
#

#!/bin/bash

###############################################
##     Colorize and add text parameters      ##
###############################################
#
blk=$(tput setaf 0) # black
red=$(tput setaf 1) # red
grn=$(tput setaf 2) # green
ylw=$(tput setaf 3) # yellow
blu=$(tput setaf 4) # blue
mga=$(tput setaf 5) # magenta
cya=$(tput setaf 6) # cyan
wht=$(tput setaf 7) # white
#
txtbld=$(tput bold) # Bold
bldblk=${txtbld}$(tput setaf 0) # black
bldred=${txtbld}$(tput setaf 1) # red
bldgrn=${txtbld}$(tput setaf 2) # green
bldylw=${txtbld}$(tput setaf 3) # yellow
bldblu=${txtbld}$(tput setaf 4) # blue
bldmga=${txtbld}$(tput setaf 5) # magenta
bldcya=${txtbld}$(tput setaf 6) # cyan
bldwht=${txtbld}$(tput setaf 7) # white
txtrst=$(tput sgr0) # Reset


###################################
##         START SCRIPT          ##
###################################

function warning() {
	echo -e ""
    echo ""
    echo -e ""
    echo -e ""
    echo -e ""
    echo ""
    read -p "Do you want to continue? [y/N] " yn
    case $yn in
        [Yy]* )
            ;;
        [Nn]* )
            exit
            ;;
        * )
            exit
            ;;
    esac
}

function get_interface() {
	echo -e "		"
    echo -e "	Get Interface	"
    echo -e "		"
	NETIF=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
	echo $NETIF
	export NETIF="$NETIF"
}

# get_dependencies
function get_dependencies() {
	echo -e "		"
    echo -e "	Install dependencies	"
    echo -e "		"
	sudo pacman -Sy --noconfirm --needed \
			firejail \
			firetools \
			firefox \
			iptables \
			bridge-utils \
			xorg-server-xephyr \
			xorg-xrandr \
			xorg-xlsclients \
			xpra \
			xterm \
			openbox \
			xephyr \
			wget
}

function firejail-bridge() {
	echo -e "		"
    echo -e "	Setting Up the Bridge	"
    echo -e "		"
    sleep 1
	sudo cp -r firejail-bridge /usr/local/sbin/firejail-bridge
	sudo chmod 755 /usr/local/sbin/firejail-bridge
}


function firejail-bridge-service() {
	echo -e "		"
    echo -e "	Creating a Persistent Bridge under systemd 	"
    echo -e "		"
    sleep 1
	sudo cp -r firejail-bridge.service /etc/systemd/system/firejail-bridge.service
	sudo systemctl daemon-reload
	sudo systemctl start firejail-bridge
	#ifconfig br10
	sudo systemctl enable firejail-bridge
}

function firejail-firewall() {
	echo -e "		"
    echo -e "	Setting Up a Routing Firewall	"
    echo -e "		"
    sleep 1
	# NETIF="enp0s3"
	sudo cp -r firejail-firewall /usr/local/sbin/firejail-firewall
	sudo chmod 755 /usr/local/sbin/firejail-firewall
}

function sysctl() {
	echo -e "		"
    echo -e "	Set Lines to modify to enable IPv4 forwarding in kernel	"
    echo -e "		"
    sleep 1
	sudo cp -r 99-ipforward.conf /etc/sysctl.d/99-ipforward.conf
	sudo sysctl --load
	sudo cat /proc/sys/net/ipv4/ip_forward
}


function iptables () {
	echo -e "		"
    echo -e "		"
    echo -e "		"
    sleep 1
	sudo systemctl enable --now iptables	
	sudo firejail-firewall
	sudo iptables-save
}

function xephyr-helper () {
	echo -e "		"
    echo -e "	Simple Xephyr clipboard reflector / xrandr rescaling script	"
    echo -e "		"
    sleep 1
	sudo cp -r xephyr-helper /usr/local/bin/xephyr-helper
	sudo chmod 755 /usr/local/bin/xephyr-helper
}

function clipboard () {
	echo -e "		"
    echo -e "	Setting Up Clipboard Sharing and Display Rescaling for Xephyr	"
    echo -e "		"
    sleep 1
# sandbox's clipboard to be automatically reflected to the host's
	touch ~/.main_clipboard_read_ok
	touch ~/.main_clipboard_write_ok
}


# function clipboard () {
#	 try starting the script directly
#	 xephyr-helper
# }

function autostart () {
	echo -e "		"
    echo -e "	Simple .desktop file to autostart xephyr-helper script	"
    echo -e "		"
    sleep 1
	# Simple .desktop file to autostart xephyr-helper script
	mkdir -pv ~/.config/autostart
	cp -r ~/.config/autostart/xephyr-helper.desktop
	chmod 755 ~/.config/autostart/xephyr-helper.desktop
}

function desktop-file () {
	echo -e "		"
    echo -e "	manually start the desktop file 	"
    echo -e "		"
    sleep 1
	#  manually start the desktop file 
	mkdir -pv ~/.local/share/applications
	ln ~/.config/autostart/xephyr-helper.desktop ~/.local/share/applications/
	gtk-launch xephyr-helper
	unlink ~/.local/share/applications/xephyr-helper.desktop
}

function check () {
	echo -e "		"
    echo -e "	Check that the script is running in the background successfully	"
    echo -e "		"
    sleep 1
	# Check that the script is running in the background successfully
	pgrep --exact xephyr-helper
}

function firejail-config () {
	echo -e "		"
    echo -e "	Configuring Firejail	"
    echo -e "		"
    sleep 1
	# Configuring Firejail
	sudo cp -r firejail.config /etc/firejail/firejail.config
}


function firefox-profile () {
	echo -e "		"
    echo -e "	Creating a (Supplementary) Local Firejail Security Profile for Firefox		"
    echo -e "		"
    sleep 1
	# Creating a (Supplementary) Local Firejail Security Profile for Firefox
	mkdir ~/.config/firejail
	cp -r firefox.profile  ~/.config/firejail/firefox.profile
}
 
function firefox-local () {
	echo -e "		"
    echo -e "	install custom security profile additions for firejailed firefox	"
    echo -e "		"
    sleep 1
	# Custom security profile additions for firejailed firefox
	sudo cp -r firefox.local /etc/firejail/firefox.local
}

function openbox-folder () {
	echo -e "		"
    echo -e "	make openbox-folder		"
    echo -e "		"
    sleep 1
	# ensure that the relevant parent directory exists 
	mkdir -pv ~/.config/openbox
}


function desktop-file () {
	echo -e "											"
    echo -e "	install Firejail-Firefox.desktop		"
    echo -e "											"
    sleep 1
	#Creating a .desktop File for X11-Firejailed Firefox
	wget https://www.iconfinder.com/icons/79853/download/png/128 -O ~/Pictures/firejailed_firefox128.png
	cp -r Firejail-Firefox.desktop ~/.local/share/applications/Firejail-Firefox.desktop
	chmod 755 ~/.local/share/applications/Firejail-Firefox.desktop
}

function end () {
	echo -e "		"
    echo -e "  end	"
    echo -e "		"
    sleep 1
}

function main() {
	#
	warning
	get_interface
	firejail-bridge
	firejail-bridge-service
	firejail-firewall
	sysctl
	iptables
	xephyr-helper
	clipboard
	autostart
	desktop-file
	check
	firejail-config
	firefox-profile
	firefox-local
	openbox-folder
	desktop-file	
	end
}

main
	
