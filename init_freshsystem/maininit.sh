
# todo:
# - install chrome ( google-chrome-stable )
# - disable keyring unlock: http://tipsonubuntu.com/2017/12/20/google-chrome-asks-password-unlock-login-keyring/
# - chinese input: https://www.pinyinjoe.com/linux/ubuntu-18-gnome-chinese-setup.htm
# - buzzing audio: https://www.reddit.com/r/archlinux/comments/7vz8k6/since_recent_update_linux_puts_sound_to_sleep_on/
#      ( read last part )


echo "Prevent system going to standby? y/n"
read readPreventStandby
#echo " - '${readPreventStandby}'"
echo ""

echo "install graphics driver? y/n"
read readInstallGraphicsDriver
#echo " - '${readInstallGraphicsDriver}'"
echo ""

echo "install KCB Keyboard driver? y/n"
read readKCB
#echo " - '${readKCB}'"
echo ""

echo "Install XMacro? y/n"
read readXMacro
#echo " - '${readXMacro}'"
echo ""

echo "Install golang mkt server? y/n"
read readMktServer
#echo " - '${readMktServer}'"
echo ""



if [ "$readPreventStandby" == "y" ]; then
	#Prevent standby
	echo ":: prevent from going standby ::"
	sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
	echo ""
fi


if [ "$readInstallGraphicsDriver" == "y" ]; then
	#graphic driver
	echo ":: graphics driver ::"
	echo "checking available drivers... ( will auto install recomended )"
	ubuntu-drivers devices
	sudo ubuntu-drivers autoinstall
	echo "drivers installed. currently installed drivers:"
	ubuntu-drivers list
	echo ""
fi

if [ "$readKCB" == "y" ]; then
	# KCB
	echo ":: corsair keyboard colors ::"
	sudo apt-get -y install git build-essential cmake libudev-dev qt5-default zlib1g-dev libappindicator-dev libpulse-dev libquazip5-dev
	sudo apt-get -y install build-essential cmake libudev-dev qt5-default zlib1g-dev libappindicator-dev libpulse-dev libquazip5-dev libqt5x11extras5-dev libxcb-screensaver0-dev libxcb-ewmh-dev libxcb1-dev qttools5-dev libdbusmenu-qt5-dev
	mkdir ~/kcb
	cd ~/kcb
	git clone https://github.com/ckb-next/ckb-next.git
	cd ckb-next
	./quickinstall
	cd ./build
	sudo make install
	systemctl enable ckb-daemon && systemctl start ckb-daemon
	echo ""
fi

if [ "$readXMacro" == "y" ]; then
	# xmacro
	echo ":: xmacro ::"
	cd ~/
	git clone https://github.com/PrimeVest/xmacro.git
	mv ./xmacro ./.xmacro
	cd ./.xmacro/scripts
	./setup.sh
	echo ""
fi

if [ "$readMktServer" == "y" ]; then
	# mkt_server
	echo ":: golang mkt server ::"
	mkdir -p ~/go/src
	cd ~/go/src
	echo "needs credentials from xp-dev"
	git clone https://xp-dev.com/git/game_mkt_server
	mv game_mkt_server mkt
	cd ./mkt
	./commands.sh s
	echo ""
fi



