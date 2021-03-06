#!/bin/bash

UNAME_RES=`uname -o`

#--------------- change this if nececary --------------
OS=Linux

if [ "$UNAME_RES" == "Msys" ]; then
	OS=Windows
fi
#------------------------------------------------------

if [ "$1" == "currentpath" ]; then
	realpath=`pwd`
	cd $2
	CurrentPath=`pwd`
	com=$3
	ar=$4
	ar2=$5
	ar3=$6
	if [ "$3" == "showallcommands" ]; then
		OS=ShowAllCommands
	fi
else
	CurrentPath=`pwd`
	com=$1
	ar=$2
	ar2=$3
	ar3=$4
fi

if [[ "$com" == "-"* ]]; then
	com=${com:1}
fi

if [ ! -d $DataFolder ]; then
	mkdir $DataFolder
fi

if [ "$OS" == "Windows" ]; then
	NC='\033[0m' # No Color
	HEADERCOLOR='\033[0;31m'
	G='\033[1;30m'
	P='\033[1;30m'
else
	NC='\033[0m' # No Color
	HEADERCOLOR='\033[0;31m'
	G='\033[0m'
	P='\033[0m'
fi

if [ "$OS" == "Windows" ]; then
	if [ ! -f ./tools/msys/msys32/usr/bin/sh.exe ]; then
		cp ./tools/msys/msys32/usr/usrbackup/sh.exe ./tools/msys/msys32/usr/bin/sh.exe	
		if [! -f ./tools/msys/msys32/usr/bin/sh.exe ]; then
			cp ./tools/msys/msys32/usr/bin/shB.exe ./tools/msys/msys32/usr/bin/sh.exe	
		fi
	fi
	NeedInputToExit=1
else
	NeedInputToExit=0
fi

if [ $# -eq 0 ] || [ "$OS" == "ShowAllCommands" ]; then

	if [ "$OS" == "Windows" ]; then
		CURRENTDIR=$(pwd)
		PacmanInstalled=0
		TEST=`pacman -h`
		NUM_CHARS=${#TEST}
		if [ $NUM_CHARS -lt 100 ] && [ -d ./tools/msys/msys32 ]; then # Pacman not installed.. but can be run
			echo "Pacman found. Running 'tools/msys/msys32/msys2.exe' ..."
			cd ./tools/msys/msys32
			echo "cd "$CURRENTDIR > ./script.sh
			echo "pwd" >> ./script.sh
			echo "./commands.sh" >> ./script.sh
			echo "exit 0" >> ./script.sh
			./msys2.exe ./script.sh
			echo "You can close this terminal"
			NeedInputToExit=0
			exit 0
			kill -9 $PPID		
			PacmanInstalled=1
		fi
	fi

#	echo -e "  -----------------------------------------------------------"
#	echo -e " | enter one of the the following options and press [ENTER]: |"
#	echo -e "  -----------------------------------------------------------"
	echo -e ""
	
# 	resize:
#	printf '\e[8;30;120t'

	if [ "$OS" == "Windows" ]; then
		echo -e " ${HEADERCOLOR}Menu:${NC}"
		echo -e "${P} -${NC}s        ${G}( Install dependencies )${NC}"
		echo -e "${P} -${NC}h        ${G}( Help )${NC}"
	else
		echo -e " ${HEADERCOLOR}Workhours:${NC}"
		echo -e "${P} -${NC}tc       ${G}( [Hour Tracking] Check houroverview of current week )${NC}"
		echo -e "${P} -${NC}te       ${G}( [Hour Tracking] log activity for today: '-te DED_SBI_IDLE 1.0' )${NC}"
		echo -e "${P} -${NC}ta       ${G}( [Hour Tracking] Show all activity types )${NC}"		
		echo -e ""
		echo -e " ${HEADERCOLOR}other:${NC}"
		echo -e "${P} -${NC}h        ${G}( help )${NC}"		
	fi
	
	echo ""
	echo " ------------------------------------------------------------"
	if [ "$OS" == "Windows" ]; then
		echo "enter the menu name and press [ENTER]: " && read input #  because windows users are spooked of technical terms
#	else
#		echo "enter the option name and press [ENTER]: " && read input #  because windows users are spooked of technical terms	
	fi
	com=$input
fi

if [ "$OS" == "ShowAllCommands" ]; then
	OS=Windows
fi

RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
C=`tput setaf 4`
NC=`tput sgr0`
SELF_PATH=`realpath $0`
CURRENTDIR=$(pwd)

CURRENTDIR_NATIVE=$CURRENTDIR
if [ "$OS" == "Windows" ]; then
	CURRENTDIR_WIN=`./tools/windows/currentCd.bat`
	CURRENTDIR_NATIVE=$CURRENTDIR_WIN
fi
	
Self="${SELF_PATH} currentpath ${CURRENTDIR}"

helpArg=""
if [ "$com" == "h" ]; then
	if [ ! -z "$ar" ]; then
		echo ""
		echo -e "help page for option '\e[32m${ar}${NC}':"
		helpArg=${ar}
	else
		echo "HELP PAGE:"
		echo " usage: "
		echo "  - execute this without any arguments to see all the available options"
		echo ""
		echo " option details: "
		echo "  - run '-h [option]' to see the option help page. for example: '-h te'"
		echo ""
	fi
fi
if [ "$com" == "fetch_hoursheet_pythonscript" ]; then
	if [ ! -d ./init_dekimo ]; then
		mkdir ./init_dekimo
	fi
	cd ./init_dekimo
	if [ ! -f timesheet.py ]; then
		wget https://raw.githubusercontent.com/JesseVanDis/config/master/init_dekimo/timesheet.py
	fi
	cd ../



elif [ "$com" == "s" ]; then
	sudo apt-get install python3-selenium

	if [ ! -d ./init_dekimo ]; then
		mkdir ./init_dekimo
	fi
	cd ./init_dekimo
	if [ ! -f ./geckodriver ]; then
		wget https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz
		tar -zxvf ./geckodriver-v0.26.0-linux64.tar.gz
		if [ -f "./geckodriver.log" ]; then
			rm ./geckodriver.log
		fi
		rm ./geckodriver-v0.26.0-linux64.tar.gz
		chmod +x ./geckodriver
		sudo mv ./geckodriver /usr/local/bin/
	fi
	cd ../


elif [ "$com" == "tc" ]; then
	$Self fetch_hoursheet_pythonscript
	cd ./init_dekimo
	echo ""
	python3 ./timesheet.py showThisWeek
	echo ""
	cd ../

elif [ "$com" == "tt" ]; then # depricated
	$Self fetch_hoursheet_pythonscript
	cd ./init_dekimo

	if [ -z "${ar2}" ]; then
		dateStr=$(date "+%-d %-m %Y")
		python3 ./timesheet.py enterActivity v "date=${dateStr}" "activity=${ar}" "duration=1.0"

	elif [ -z "${ar3}" ]; then
		dateStr=$(date "+%-d %-m %Y")
		python3 ./timesheet.py enterActivity v "date=${dateStr}" "activity=${ar}" "duration=${ar2}"
	else
		python3 ./timesheet.py enterActivity v "date=${ar}" "activity=${ar2}" "duration=${ar3}"
	fi
	cd ../

elif [ "$com" == "te" ]; then
	#  -tt date="03 01 2020" task=DED_SBI_IDLE durationDays=1.0 place=Delft distanceKm=1"
	#  -tt da="03 01 2020" ta=DED_SBI_IDLE du=1.0 pl=Delft km=1"
	dateStr=$(date "+%-d %-m %Y")
	taskStr="DED_SBI_IDLE"
	durationDaysStr="1.0"
	placeStr="Delft"
	distanceKmStr="0"
	verbose=false
	
	for arg in "$@"
	do
		if [[ "${arg}" == "da="* ]]; then dateStr="${arg:3}"; fi
		if [[ "${arg}" == "date="* ]]; then dateStr="${arg:5}"; fi
		if [[ "${arg}" == "ta="* ]]; then taskStr="${arg:3}"; fi
		if [[ "${arg}" == "task="* ]]; then taskStr="${arg:5}"; fi
		if [[ "${arg}" == "du="* ]]; then durationDaysStr="${arg:3}"; fi
		if [[ "${arg}" == "durationDays="* ]]; then durationDaysStr="${arg:13}"; fi
		if [[ "${arg}" == "pl="* ]]; then placeStr="${arg:3}"; fi
		if [[ "${arg}" == "place="* ]]; then placeStr="${arg:6}"; fi
		if [[ "${arg}" == "km="* ]]; then distanceKmStr="${arg:3}"; fi
		if [[ "${arg}" == "distanceKm="* ]]; then distanceKmStr="${arg:11}"; fi
		if [[ "${arg}" == "v" ]]; then verbose=true; fi
	done

	cd ./init_dekimo
	if [ $verbose == true ]; then
		echo "-- input --"
		echo "date: ${dateStr}"
		echo "task: ${taskStr}"
		echo "duration: ${durationDaysStr}"
		echo "place: ${placeStr}"
		echo "distance: ${distanceKmStr}"
		echo "-----------"
		echo "starting running python script './init_dekimo/timesheet.py'..."
		python3 ./timesheet.py enterActivity v "date=${dateStr}" "activity=${taskStr}" "duration=${durationDaysStr}" "location=${placeStr}" "distance=${distanceKmStr}"
	else
		python3 ./timesheet.py enterActivity "date=${dateStr}" "activity=${taskStr}" "duration=${durationDaysStr}" "location=${placeStr}" "distance=${distanceKmStr}"
	fi


elif [ "${helpArg}" == "te" ]; then
	echo "there are 3 ways to enter an activity, examples of the are as follows:"
	echo "keep in mind that the order matters"
	echo "  -te DED_SBI_IDLE                   ( log activity today with duration 1.0d )"
	echo "  -te DED_SBI_IDLE 0.5               ( log activity today with duration 0.5d )"
	echo "  -te \"03 01 2020\" DED_SBI_IDLE 1.0  ( only works for current week days so far )"
	echo "  -tt date=\"03 01 2020\" task=DED_SBI_IDLE time=1.0 place=Delft distanceKm=1"
	echo ""


elif [ "$com" == "ta" ]; then
	$Self fetch_hoursheet_pythonscript
	cd ./init_dekimo
	echo ""	
	python3 ./timesheet.py showAllActivityTypes
	echo ""
	cd ../

elif [ ! -z "${helpArg}" ]; then
	echo "No help page available for '${helpArg}' yet"
else
	NeedInputToExit=0
	exit
fi

#if [ "$1" != "currentpath" ]; then 	
#	if [ $NeedInputToExit -eq 1 ]; then
#		echo " ------------------------------------------------------------"
#		echo "Done!"
#		echo "Press [ENTER] to exit"
#		read input
#	fi
#fi

#mkdir ./Debug
#cd ./Debug
#cmake ../src
#make 
#valgrind --tool=memcheck ./Runner 
#cd ../
