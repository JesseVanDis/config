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
	if [ "$3" == "showallcommands" ]; then
		OS=ShowAllCommands
	fi
else
	CurrentPath=`pwd`
	com=$1
	ar=$2
	ar2=$3
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
		echo -e "${P} -${NC} h        ${G}( Help )${NC}"		
	else
		echo -e " ${HEADERCOLOR}Check:${NC}"
		echo -e "${P} -${NC} hc       ${G}( [PC] Check houroverview of current week )${NC}"		
		echo -e ""
		echo -e " ${HEADERCOLOR}other:${NC}"
		echo -e "${P} -${NC} h        ${G}( help )${NC}"		
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

export PATH="$BlenderPath:$PATH"
export PATH="$CURRENTDIR:$PATH"
export PATH="$CURRENTDIR/tools:$PATH"
if [ "$OS" == "Windows" ]; then
	export PATH="$CURRENTDIR/tools/windows:$PATH"
	export PATH="$CURRENTDIR/tools/blender/blender:$PATH"
	export PATH="$CURRENTDIR/tools/msys/msys32/mingw32/bin:$PATH"
	export PATH="$CURRENTDIR/tools/msys/msys32/mingw32/i686-w64-mingw32/bin:$PATH"	
	export PATH="$CURRENTDIR/tools/msys/msys32/usr/bin:$PATH"	
	export PATH="$CURRENTDIR/tools/imageMagick:$PATH"	
	export PATH="$CURRENTDIR/tools/python2:$PATH"	
fi

if [ -d $JavaPath ]; then
	export PATH="$JavaPath:$PATH"
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

elif [ "$com" == "hc" ]; then
	$Self fetch_hoursheet_pythonscript
	cd ./init_dekimo
	echo ""
	python3 ./timesheet.py showThisWeek
	echo ""
	cd ../

elif [ "$com" == "h" ]; then
	echo "HELP PAGE: (for now just showing some tips)"
	echo " tips: "
	echo "  - open the git bash and enter './commands.sh [menu name]' where [menu name] is the menu name you like to be executed"
	echo "  - type 'sa' to show all commands. It is not gauranteed that all of them work since they are usually made linux."

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
