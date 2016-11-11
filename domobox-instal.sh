#!/bin/bash
 
## This script was originally developed for the Raspberry Pi - on non-Pi systems such as the FriendlyArm M1 I use Armbian. 
## Don't expect ports to work out of the box on non-Pi
## Also, for all systems, after you load this script and before running, you need to give it execute
## permissions. See http://tech.scargill.net/orange-pi-pc-battle-of-the-pis/
## 23/5/2016 Tested on Pi3 with latest software Jessie released 10/05/2016
## 16/5/2016 Tested on NanoPi M1 - wiped graphical interface but see last comment to get it back (got 3 UARTS out of the M1)
## 22/06/2016 added questions for non-Pi boards
## 22/06/2016 tested on NanoPi NEO using Armbian Jessie Server http://www.armbian.com/donate/?f=Armbian_5.20_Nanopineo_Debian_jessie_3.4.112.7z
## Important: For NEO (or similar) when asked by Armbian to make a new user - make it user "pi"
##
## IMPORTANT - user PI must have script execute permission for this script.
##
## Assuming access as pi user. Please note this will NOT WORK AS ROOT - The Node-Red install will fail.
## Do not use this script as SUDO.
##
## Typically, sitting in your home directory (/home/pi) as user Pi you might want to use NANO to install this script
## and after giving the script execute permission (sudo chmod 0744 /home/pi/script.sh)
## you could run the file as ./script.sh
##
## Includes Mosquitto with web sockets (Port 9001), SQLITE ( xxx.xxx.xxx.xxx/phpliteadmin),
## Node-Red (xxx.xxx.xxx:1880), Node-Red-Dashboard (xxx.xxx.xxx.xxx:1880/ui) and Webmin(xxx.xxx.xxx:10000)
## as well as web page based items like /phpliteadmin and /phpsysinfo
##
## http://tech.scargill.net - much of this was thanks to help from others!
## 
## Some mods in here including bits to remove manual work - from reader Antonio Fragola - MrShark. Thank you.
##
## If you want Node-Red security you need to add this to the settings.js file in /home/pi/.node-red
##
##
##    functionGlobalContext: {
##       os:require('os'),
##        // bonescript:require('bonescript'),
##        // jfive:require("johnny-five"),
##       moment:require('moment'),
##       fs:require('fs')
##    },
## 
##    adminAuth: {
##    type: "credentials",
##    users: [{
##       username: "admin",
##        password: "your encrypted password see node red site",
##        permissions: "*"
##    }]
##},
##
##  httpNodeAuth: {user:"user", pass:"your encrypted password see node red site"},


# ROUTINES
# Here at the beginning, a load of useful routines - see further down

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
startTime="$(date +%s)"
columns=$(tput cols)
user_response=""
 
# High Intensity
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White
 
# Bold High Intensity
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIPurple='\e[1;95m'     # Purple
BIMagenta='\e[1;95m'    # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

#!/bin/bash
 
skip=0
other=0
 
clean_stdin()
{
while read -r -t 0; do
    read -n 256 -r -s
done
}
 
# Permanent loop until both passwords are the same..
function user_input {
  local VARIABLE_NAME=${1}
  local VARIABLE_NAME_1="A"
  local VARIABLE_NAME_2="B"
  while true; do
      printf "${BICyan}$2: ${BIWhite}";
      if [ "$3" = "hide" ] ; then
        stty -echo;
      fi
      read VARIABLE_NAME_1;
      stty echo;
      if [ "$3" = "hide" ] ; then
          printf "\n${BICyan}$2 (again) : ${BIWhite}";
          stty -echo;
          read VARIABLE_NAME_2;
          stty echo;
      else
          VARIABLE_NAME_2=$VARIABLE_NAME_1;
      fi
      if [ $VARIABLE_NAME_1 != $VARIABLE_NAME_2 ] ; then
         printf "\n${BIRed}Sorry, did not match!${BIWhite}\n";
      else
         break;
       fi
  done
  readonly ${VARIABLE_NAME}=$VARIABLE_NAME_1;
  if [ "$3" == "hide" ] ; then
     printf "\n";
  fi     
}

stopit=0
other=0
yes=0
nohelp=0
hideother=0

 
timecount(){
	sec=30
	while [ $sec -ge 0 ]; do

		if [ $nohelp -eq 1 ]; then

	if [ $hideother -eq 1 ]; then
		printf "${BIPurple}Continue ${BIWhite}y${BIPurple}(es)/${BIWhite}n${BIPurple}(o)/${BIWhite}a${BIPurple}(ll)/${BIWhite}e${BIPurple}(nd)-  ${BIGreen}00:0$min:$sec${BIPurple} remaining\033[0K\r${BIWhite}"
else
		printf "${BIPurple}Continue ${BIWhite}y${BIPurple}(es)/${BIWhite}o${BIPurple}(ther)/${BIWhite}e${BIPurple}(nd)-  ${BIGreen}00:0$min:$sec${BIPurple} remaining\033[0K\r${BIWhite}"
fi

		else
			printf "${BIPurple}Continue ${BIWhite}y${BIPurple}(es)/${BIWhite}h${BIPurple}(elp)-  ${BIGreen}00:0$min:$sec${BIPurple} remaining\033[0K\r${BIWhite}"
		fi
		sec=$((sec-1))
		trap '' 2
		stty -echo
		read -t 1 -n 1 user_response
		stty echo
		trap - 2
		if [ -n  "$user_response" ]; then
			break
		fi                 
	done
}


task_start(){
printf "\r\n" 
printf "${BIGreen}%*s\n" $columns | tr ' ' -
printf "$1"
clean_stdin
skip=0
printf "\n${BIGreen}%*s${BIWhite}\n" $columns | tr ' ' -
elapsedTime="$(($(date +%s)-startTime))"
printf "Elapsed Time: %02d hrs %02d mins %02d secs\n" "$((elapsedTime/3600%24))" "$((elapsedTime/60%60))" "$((elapsedTime%60))"
clean_stdin
if [ "$user_response" != "a" ]; then
    timecount
fi
echo -e "                                                                        \033[0K\r"
if  [ "$user_response" = "e" ]; then
    printf "${BIWhite}"
    exit 1
fi 
if  [ "$user_response" = "n" ]; then
    skip=1
fi 
if  [ "$user_response" = "o" ]; then
    other=1
fi 
if  [ "$user_response" = "h" ]; then
    stopit=1
fi 
if  [ "$user_response" = "y" ]; then
    yes=1
fi 
if [ -n  "$2" ]; then
    if [ $skip -eq 0 ]; then
        printf "${BIYellow}$2${BIWhite}\n"
    else
        printf "${BICyan}%*s${BIWhite}\n" $columns '[SKIPPED]'
    fi
fi
}
 
task_end(){
    printf "${BICyan}%*s${BIWhite}\n" $columns '[OK]'
}
 
 
#
# MAIN SECTION OF SCRIPT - action begins here
#
printf "\033[2J\033[;H"
task_start "${BIRed}!! IMPORTANT !!\r\n\r\nFirst time? ONLY hit y(es) if this is a REAL pi OR you have already added in user Pi\r\nand given them SUDO permissions - otherwise hit h(elp)" ""
if [ $stopit -eq 1 ]; then
	printf "${BIYellow}For non-Pi boards (which may or may not work) you should ensure that\r\n"
	printf "you have resized the SD if necessary to make full use of your SD\r\n"
	printf "and that you have used the following commands AS ROOT:\r\n\r\n${IGreen}"
	printf "1. adduser pi\r\n"
	printf "2. usermod pi -g sudo   # that makes user Pi part of the sudo group\r\n"
	printf "3. echo \"pi ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/pi\r\n"
	printf "4. chmod 0440 /etc/sudoers.d/pi\r\n\r\n${IYellow}"
	printf "When complete - reboot, log in as user PI and run the script i.e.  ./script.sh\r\n"
	printf "${IWhite}\r\n\r\n"
	task_end
	exit
fi

nohelp=1

printf "${BIYellow}To minimise input later on, enter a general admin username and password here:\r\n\r\n"
user_input generaluser "Enter general user (admin for example)"
user_input generalpass "Enter general password" "hide"

 
task_start "If this is a genuine Pi hit Y(es) otherwise hit o(ther) for OTHER board" "Ok"
if [ $other -eq 1 ]; then
	printf "${ICyan}\r\nContinuing, assuming this is NOT a genuine Raspberry Pi$\r\nAdding PI user to various groups for you{IWhite}\r\n"
	sudo adduser pi sudo
	sudo adduser pi adm
	sudo adduser pi dialout
	sudo adduser pi cdrom
	sudo adduser pi audio
	sudo adduser pi video
	sudo adduser pi plugdev
	sudo adduser pi games
	sudo adduser pi users
	sudo adduser pi netdev
	sudo adduser pi input
	else
	printf "${IBlue}\r\nContinuing, assuming this IS a genuine Raspberry Pi${IWhite}\r\n"
	task_end
fi  
 
hideother=1

task_start "Install General Upgrade and Prerequisites?" "UPDATING/UPGRADING then enabling PING and SAMBA (to access the hostname externally - and ping fix etc)"
if [ $skip -eq 0 ]; then
	sudo apt-get update -y
	sudo apt-get upgrade -y 
	# fix for RPI treating PING as a root function - by Dave
	sudo setcap cap_net_raw=ep /bin/ping
	sudo setcap cap_net_raw=ep /bin/ping6
    sudo apt-get install jed
	# If experimenting on another computer and you want to create user PI (which you should to use this script)....
	# you'll need to add  them to groups
	# sudo adduser pi
	# sudo passwd pi  

	# for non PI systems
	# sudo visudo
	#     and in there - you want to mod sudo user to the following....
	#     %sudo   ALL=(ALL:ALL) NOPASSWD: ALL
	#     Save that - the constant password checking goes away
	#
	# sudo nano /etc/hosts  - change 127.0.0.1 entry
	# sudo nano /etc/hostname - only one entry in there - change
	# sudo /etc/init.d/hostname.sh
	# sudo reboot
	 
	 
	# Prerequisite suggested by Julian and adding in python-dev - and stuff I've added for SAMBA and telnet
	sudo apt-get install -y bash-completion unzip build-essential git python-serial scons libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libsqlite3-dev subversion libcurl4-openssl-dev libusb-dev python-dev cmake curl samba samba-common samba-common-bin winbind telnet
	# libboost-thread-dev libboost-all-dev
	task_end
fi
 
task_start "Install Mosquitto?" "Loading Mosquitto and setting up user"
if [ $skip -eq 0 ]; then
	# installation of Mosquitto/w/Websockets
	cd
	wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key -O - | sudo apt-key add -
	echo "deb http://repo.mosquitto.org/debian jessie main" |sudo tee /etc/apt/sources.list.d/mosquitto-jessie.list
	sudo apt-get update -y && sudo apt-get install mosquitto -y
	sudo bash -c "echo -e \"listener 9001\nprotocol websockets\nlistener 1883\nallow_anonymous false\npassword_file /etc/mosquitto/passwords\" > /etc/mosquitto/conf.d/websockets.conf"
	sudo touch /etc/mosquitto/passwords
	sudo mosquitto_passwd  -b /etc/mosquitto/passwords $generaluser $generalpass
	task_end
fi

# Moved sqlite3 so that node-red sql node will install
# use back facing quotes in here - no idea why.
# Changed the order of installation of Apache etc to solve issues with ARMBIAN
#
task_start "Install Apache Installation with PHP and SQLITE and PHPLITEADMIN?" "Installing Apache and PHP and SQLITE and PHPLITEADMIN..."
if [ $skip -eq 0 ]; then
	cd
	sudo groupadd -f -g33 www-data
	sudo apt-get -qq --yes -o=Dpkg::Use-Pty=0 --force-yes install apache2 php5 libapache2-mod-php5
	cd /var/www/html
	sudo mkdir phpliteadmin
	cd phpliteadmin
	sudo wget --no-verbose https://bitbucket.org/phpliteadmin/public/downloads/phpLiteAdmin_v1-9-6.zip
	sudo unzip phpLiteAdmin_v1-9-6.zip
	sudo mv phpliteadmin.php index.php
	sudo mv phpliteadmin.config.sample.php phpliteadmin.config.php
	sudo rm *.zip
	sudo mkdir themes
	cd themes
	sudo wget --no-verbose https://bitbucket.org/phpliteadmin/public/downloads/phpliteadmin_themes_2013-12-26.zip
	sudo unzip phpliteadmin_themes_2013-12-26.zip
	sudo rm *.zip
	sudo sed -i -e 's#\$directory = \x27.\x27;#\$directory = \x27/home/pi/dbs/\x27;#g' /var/www/html/phpliteadmin/phpliteadmin.config.php
	sudo sed -i -e "s#\$password = \x27admin\x27;#\$password = \x27$generalpass\x27;#g" /var/www/html/phpliteadmin/phpliteadmin.config.php
	sudo sed -i -e "s#\$subdirectories = false;#\$subdirectories = true;#g" /var/www/html/phpliteadmin/phpliteadmin.config.php
	cd
	task_end
fi

# HP Modif	
task_start "Install SQLITE and table?" "Installing SQLITE..."
if [ $skip -eq 0 ]; then
	cd
	sudo apt-get install -y sqlite3 php5-sqlite
	mkdir dbs
	sqlite3 /home/pi/dbs/iot.db << EOF
	CREATE TABLE IF NOT EXISTS \`pinDescription\` (
	  \`pinID\` INTEGER PRIMARY KEY NOT NULL,
	  \`pinNumber\` varchar(2) NOT NULL,
	  \`pinDescription\` varchar(255) NOT NULL
	);
	CREATE TABLE IF NOT EXISTS \`pinDirection\` (
	  \`pinID\` INTEGER PRIMARY KEY NOT NULL,
	  \`pinNumber\` varchar(2) NOT NULL,
	  \`pinDirection\` varchar(3) NOT NULL
	);
	CREATE TABLE IF NOT EXISTS \`pinStatus\` (
	  \`pinID\` INTEGER PRIMARY KEY NOT NULL,
	  \`pinNumber\` varchar(2)  NOT NULL,
	  \`pinStatus\` varchar(1) NOT NULL
	);
	CREATE TABLE IF NOT EXISTS \`users\` (
	  \`userID\` INTEGER PRIMARY KEY NOT NULL,
	  \`username\` varchar(28) NOT NULL,
	  \`password\` varchar(64) NOT NULL,
	  \`salt\` varchar(8) NOT NULL
	);
	CREATE TABLE IF NOT EXISTS \`device_list\` (
	  \`device_name\` varchar(80) NOT NULL DEFAULT '',
	  \`device_description\` varchar(80) DEFAULT NULL,
	  \`device_attribute\` varchar(80) DEFAULT NULL,
	  \`logins\` int(11) DEFAULT NULL,
	  \`creation_date\` datetime DEFAULT NULL,
	  \`last_update\` datetime DEFAULT NULL,
	  PRIMARY KEY (\`device_name\`)
	);

	CREATE TABLE IF NOT EXISTS \`readings\` (
	  \`recnum\` INTEGER PRIMARY KEY, 
	  \`location\` varchar(20), 
	  \`value\` int(11) NOT NULL, 
	  \`logged\` timestamp not NULL DEFAULT CURRENT_TIMESTAMP , 
	  \`device_name\` varchar(40) not null, 
	  \`topic\` varchar(40) not null
	);


	CREATE TABLE IF NOT EXISTS \`pins\` (
	  \`gpio0\` int(11) NOT NULL DEFAULT '0',
	  \`gpio1\` int(11) NOT NULL DEFAULT '0',
	  \`gpio2\` int(11) NOT NULL DEFAULT '0',
	  \`gpio3\` int(11) NOT NULL DEFAULT '0'
	);
	INSERT INTO PINS VALUES(0,0,0,0);
	CREATE TABLE IF NOT EXISTS \`temperature_record\` (
	  \`device_name\` varchar(64) NOT NULL,
	  \`rec_num\` INTEGER PRIMARY KEY,
	  \`temperature\` float NOT NULL,
	  \`date_time\` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
	);
	CREATE TABLE IF NOT EXISTS \`Device\` (
	  \`DeviceID\` INTEGER PRIMARY KEY,
	  \`DeviceName\` TEXT NOT NULL
	);
	CREATE TABLE IF NOT EXISTS \`DeviceData\` ( 
	  \`DataID\` INTEGER PRIMARY KEY, 
	DeviceID INTEGER,
	  \`DataName\` TEXT, FOREIGN KEY(DeviceID ) REFERENCES Device(DeviceID) 
	);
	CREATE TABLE IF NOT EXISTS \`Data\` ( 
	SequenceID INTEGER PRIMARY KEY,
	  \`DeviceID\` INTEGER NOT NULL,
	  \`DataID\` INTEGER NOT NULL,
	  \`DataValue\` NUMERIC NOT NULL, 
	  \`epoch\` NUMERIC NOT NULL, 
	  \`timestamp\` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP , FOREIGN KEY(DataID, DeviceID ) REFERENCES DeviceData(DAtaID, DeviceID ) 
	);
	.exit
EOF
	 
	cd
	chmod 777 /home/pi/dbs
	chmod 666 /home/pi/dbs/iot.db
	cd
	task_end
fi
# HP Modif end

task_start "Install NODEJS?" "Installing NODEJS"
if [ $skip -eq 0 ]; then
	# ====================== Aidans Additions to install node and npm =============================
	echo " ============================ Installing NODEJS ========================================="
	curl -sL https://deb.nodesource.com/setup_4.x > nodesetup.sh
	sudo bash nodesetup.sh
	sudo apt-get install nodejs -y
	task_end
fi


# =============================================================================================
task_start "Install Node-Red?" "Installing Node-Red"
if [ $skip -eq 0 ]; then
	#sudo npm cache clean
	sudo npm install -g --unsafe-perm node-red
	sudo wget https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/nodered.service -O /lib/systemd/system/nodered.service
	sudo wget https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-start -O /usr/bin/node-red-start
	sudo wget https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/node-red-stop -O /usr/bin/node-red-stop
	#sudo sed -i -e 's#=pi#=%USER#g' /lib/systemd/system/nodered.service
	sudo chmod +x /usr/bin/node-red-st*
	sudo systemctl daemon-reload
	mkdir .node-red
	cd .node-red
	npm install node-red-admin
	npm install moment
	npm install node-red-contrib-config
	npm install node-red-contrib-grove
	npm install node-red-contrib-bigtimer
	npm install node-red-contrib-esplogin
	npm install node-red-contrib-timeout
	npm install node-red-node-pushbullet
	npm install node-red-node-openweathermap
	npm install node-red-node-google
	npm install node-red-node-sqlite
	npm install node-red-node-emoncms
	npm install node-red-node-geofence
	npm install node-red-contrib-ivona
	npm install node-red-contrib-moment
	npm install node-red-contrib-particle
	npm install node-red-contrib-web-worldmap
	npm install node-red-contrib-graphs
	npm install node-red-contrib-isonline
	npm install node-red-node-ping
	npm install node-red-node-random
	npm install node-red-node-smooth
	npm install node-red-contrib-npm
	npm install node-red-contrib-file-function
	npm install node-red-contrib-admin
	npm install node-red-contrib-boolean-logic
	npm install node-red-node-arduino
	npm install node-red-contrib-blynk-websockets
	npm install node-red-dashboard
    npm install node-red-node-darksky
	sudo npm install bcryptjs

	if [ $other -eq 0 ]; then
		npm install node-red-node-ledborg
		npm install node-red-contrib-gpio
		npm install raspi-io
	fi

	task_end
fi

if [ $other -eq 1 ]; then
	task_start "Install GPIO library for H3 based machines - eg NanoPi range?" "Installing GPIO library"
	if [ $skip -eq 0 ]; then
		# Install NanoPi H3 based IO library
		git clone https://github.com/zhaolei/WiringOP.git -b h3
		cd WiringOP
		chmod +x ./build
		sudo ./build
		cd
		task_end
	fi
fi
 
task_start "Install Webmin?" "Installing Webmin"
if [ $skip -eq 0 ]; then
	#cd
	#mkdir webmin
	#cd webmin
	#wget --no-verbose http://prdownloads.sourceforge.net/webadmin/webmin-1.820.tar.gz
	#sudo gunzip -q webmin-1.820.tar.gz
	#tar -xf webmin-1.820.tar
	#sudo rm *.tar
	#cd webmin-1.820
	#sudo ./setup.sh /usr/local/Webmin
	wget http://www.webmin.com/jcameron-key.asc -O - | sudo apt-key add -
	echo "deb http://download.webmin.com/download/repository sarge contrib" | sudo tee /etc/apt/sources.list.d/webmin.list > /dev/null
	sudo apt-get update -y
	sudo apt-get install webmin -y
	task_end
fi
 
task_start "Install MPG123?" "Installing MPG123..."
if [ $skip -eq 0 ]; then
	sudo apt-get install -y mpg123
	task_end
fi
 
#
# This works a treat on the NanoPi NEO using H3 and Armbian - should not do any harm on other systems as it's not installed!
#
if [ -f /etc/armbian-release ]; then
	task_start "Install OPI-Monitor (:8888) modified for H3 (SKIP if not using H3 processor)?" "Installing OPI-Monitor"
	if [ $skip -eq 0 ]; then
		sudo armbianmonitor -r
		task_end
	fi
fi
 

#task_start "Install Internet Time Updater for Webmin (NTPUpdate)?" "Installing NTPUpdate"
#if [ $skip -eq 0 ]; then
	#sudo apt-get -qq --yes -o=Dpkg::Use-Pty=0 --force-yes install ntpdate
	#task_end
#fi
 
 
#task_start "Install Email SMTP?" "Installing Email utils and SMTP..."
#if [ $skip -eq 0 ]; then
	#cd
	#sudo apt-get  -qq --yes -o=Dpkg::Use-Pty=0 --force-yes install mailutils ssmtp
	#task_end
#fi
 
task_start "Install SCREEN?" "Installing SCREEN"
if [ $skip -eq 0 ]; then
	cd
	sudo apt-get install screen
	task_end
fi
 
task_start "Install PHPSYSINFO?" "Installing phpsysinfo"
if [ $skip -eq 0 ]; then
	sudo apt-get install -y phpsysinfo
	sudo ln -s /usr/share/phpsysinfo /var/www/html
	task_end
fi
 
printf "${BIMagenta}Please wait... starting the Node-Red service - stopping - updating a file.\r\nThis will take several seconds\r\n${BIWhite}";

sudo service nodered start ; sleep 5 ; sudo service nodered stop
sed -i -e "s/\/\/\ os:require('os')\,/os:require('os')\,\n\tmoment:require('moment')/g" .node-red/settings.js
echo " "

# you may want to use these on a Pi or elswhere to force either a graphical or command line environment
#sudo systemctl set-default multi-user.target
#sudo systemctl set-default graphical.target

sudo systemctl enable nodered.service

# Allow remote root login and speed up SSH
sudo sed -i -e 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i -e 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i '$ a UseDNS no' /etc/ssh/sshd_config

sudo /etc/init.d/ssh restart

task_start "Update PI and ROOT passwords?" "updating passwords"
if [ $skip -eq 0 ]; then
	echo "Update your PI password"
	sudo passwd pi
	echo "Update your ROOT password"
	sudo passwd root
	task_end
fi

# Upgrade to latest NPM at your own risk
task_start "Update to latest NPM?" "Updating NPM"
if [ $skip -eq 0 ]; then
	sudo npm install npm@latest -g
	task_end
fi

# Upgrade to latest NPM at your own risk
task_start "Add CU to enable serial VT100 mode for terminals?" "Adding CU"
if [ $skip -eq 0 ]; then
	sudo apt-get install cu
	task_end
fi

# Drop in an index file and css for a menu page
task_start "Add index/link page and a little css?" "Adding index.html and a little css"
if [ $skip -eq 0 ]; then
	sudo wget -qq http://www.scargill.net/iot/index.html -O /var/www/html/index.html
	sudo wget -qq http://www.scargill.net/iot/reset.css -O /var/www/html/reset.css
	task_end
fi

if [ $other -eq 0 ]; then
	sudo chmod 0660 /dev/ttyAMA0
fi

if [ $other -eq 0 ]; then
	task_start "Remove WolfRam on Pi - save lots of space?" "Removing Wolfram"
	if [ $skip -eq 0 ]; then
		sudo apt-get purge wolfram-engine
		sudo apt-get autoremove
		task_end
	fi

	task_start "Remove LibreOffice on Pi - save lots of space?" "Removing LibreOffice"
	if [ $skip -eq 0 ]; then
		sudo apt-get remove --purge libreoffice*
		sudo apt-get clean
		sudo apt-get autoremove
		task_end
	fi
fi

# HP Modif
task_start "Install Domogeek?" "Installing Domogeek"
if [ $skip -eq 0 ]; then
	cd
    mkdir domogeek
    cd domogeek
    wget --no-verbose https://raw.github.com/pypa/pip/master/contrib/get-pip.py
    sudo python get-pip.py
    sudo python -m pip install web.py beautifulsoup4 icalendar requests redis
    sudo apt-get install redis-server -y
    wget --no-verbose https://github.com/guiguiabloc/api-domogeek/archive/master.zip
    unzip -qq master.zip
    cd api-domogeek-master
    sudo chmod +x apidomogeek.py
    sudo sed -i -e 's#listenport = "80"#listenport = "81"#g' apidomogeek.py
    sudo sed -i -e 's#localapiurl= "http://api.domogeek.fr"#localapiurl= "http://domogeek.entropialux.com"#g' apidomogeek.py
    sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/domogeek.init -O /etc/init.d/domogeek
    sudo chmod 755 /etc/init.d/domogeek
    sudo systemctl enable domogeek.service
	task_end
fi

task_start "Install Script qualité de l'air?" "Installing Qualité de l'air"
if [ $skip -eq 0 ]; then
	cd
    wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/air.tgz
    sudo tar xfz air.tgz -C /var/www/html
    sudo chown -R www-data:www-data /var/www/html/air
    sudo crontab /var/www.html/air/air.crontab
	cd
	task_end
fi
# HP Modif End

# Something I did wrong here meant the FriendlyArm Nanopi M1 came up with no graphical interface.  sudo apt-get-install xorg fixed that followed by xstart
printf "${BIMagenta}All done.\r\n\r\n"
printf  "${ICyan}If you wish to change the hostname - change value in /etc/hosts\r\n"
printf  "Change also value in /etc/hostname to the same\r\nthen run sudo /etc/init.d/hostname.shs\r\n\r\n"
printf  "${BIMagenta}**** PLEASE REBOOT NOW ****"
