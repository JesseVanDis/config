#!/bin/bash
cd "$(dirname "$0")"

# todo:
# - install chrome ( google-chrome-stable )

Disabled=./maininit.sh
stateDir="./.state/"

checkGit="${stateDir}checkGit"


# to default-enable ssh on your pi, without needing the screen, check the following:
# https://linuxize.com/post/how-to-enable-ssh-on-raspberry-pi/



# ----------------
# CHECK
# ----------------

if [ ! -f "${checkGit}" ]; then
	echo "setup git? y/n"
	read readSetupGit
	echo ""
fi

# ----------------
# INSTALL
# ----------------
if [ ! -d "${stateDir}" ]; then
	# first time startup
	sudo apt update	
	mkdir -p "${stateDir}"
fi


if [ "$readSetupGit" == "y" ]; then
	# setup_git
	echo ":: Git ::"
	sudo apt-get -y install git
	git config --global credential.helper store # save username and password when pulling
	git config --global user.email "pri_jesse@hotmail.com"
	git config --global user.name "Jesse van Dis - rpi"
	echo "1" > "${checkGit}"
fi



