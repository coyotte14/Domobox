#!/bin/bash

#
# Installation 
# wget https://raw.githubusercontent.com/coyotte14/Domobox/master/domobox-instal-HP_menu.sh
# chmod +x  domobox-instal-HP_menu.sh
#
## ROUTINES
## Here at the beginning, a load of useful routines - see further down

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
    printf "Elapsed: %02d hrs %02d mins %02d secs\n" "$((elapsedTime/3600%24))" "$((elapsedTime/60%60))" "$((elapsedTime%60))"
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


# credits to DietPi

CPU_TEMP_CURRENT='Unknown'
CPU_TEMP_PRINT='Unknown'
ACTIVECORES=$(grep -c processor /proc/cpuinfo)

#Array to store possible locations for temp read.
aFP_TEMPERATURE=(
    '/sys/class/thermal/thermal_zone0/temp'
    '/sys/devices/platform/sunxi-i2c.0/i2c-0/0-0034/temp1_input'
    '/sys/class/hwmon/hwmon0/device/temp_label'
)

Obtain_Cpu_Temp(){
    for ((i=0; i<${#aFP_TEMPERATURE[@]}; i++))
    do
        if [ -f "${aFP_TEMPERATURE[$i]}" ]; then
            CPU_TEMP_CURRENT=$(cat "${aFP_TEMPERATURE[$i]}")
            # - Some devices (pine) provide 2 digit output, some provide a 5 digit ouput.
            #       So, If the value is over 1000, we can assume it needs converting to 1'c
            if (( $CPU_TEMP_CURRENT >= 1000 )); then
                CPU_TEMP_CURRENT=$( echo -e "$CPU_TEMP_CURRENT" | awk '{print $1/1000}' | xargs printf "%0.0f" )
            fi
            if (( $CPU_TEMP_CURRENT >= 70 )); then
                CPU_TEMP_PRINT="\e[91mWarning: $CPU_TEMP_CURRENT'c\e[0m"
                elif (( $CPU_TEMP_CURRENT >= 60 )); then
                CPU_TEMP_PRINT="\e[38;5;202m$CPU_TEMP_CURRENT'c\e[0m"
                elif (( $CPU_TEMP_CURRENT >= 50 )); then
                CPU_TEMP_PRINT="\e[93m$CPU_TEMP_CURRENT'c\e[0m"
                elif (( $CPU_TEMP_CURRENT >= 40 )); then
                CPU_TEMP_PRINT="\e[92m$CPU_TEMP_CURRENT'c\e[0m"
                elif (( $CPU_TEMP_CURRENT >= 30 )); then
                CPU_TEMP_PRINT="\e[96m$CPU_TEMP_CURRENT'c\e[0m"
            else
                CPU_TEMP_PRINT="\e[96m$CPU_TEMP_CURRENT'c\e[0m"
            fi
            break
        fi
    done
}

LOGFILE=$HOME/$0-`date +%Y-%m-%d_%Hh%Mm`.log

printl() {
	printf $1
	echo -e $1 >> $LOGFILE
}

printstatus() {
    Obtain_Cpu_Temp
    h=$(($SECONDS/3600));
    m=$((($SECONDS/60)%60));
    s=$(($SECONDS%60));
    printf "\r\n${BIGreen}==\r\n== ${BIYellow}$1"
    printf "\r\n${BIGreen}== ${IBlue}Total: %02dh:%02dm:%02ds Cores: $ACTIVECORES Temperature: $CPU_TEMP_PRINT \r\n${BIGreen}==${IWhite}\r\n\r\n"  $h $m $s;
	echo -e "############################################################" >> $LOGFILE
	echo -e $1 >> $LOGFILE
}


############################################################################
##
## MAIN SECTION OF SCRIPT - action begins here
##
#############################################################################
##

printstatus "Welcome to the script."

AQUIET="-qq"
NQUIET="-s"

# install sudo on devices without it
[ ! -x /usr/bin/sudo ] && apt-get $AQUIET -y update > /dev/null 2>&1 && apt-get $AQUIET -y install sudo 2>&1 | tee -a $LOGFILE

# Whiptail menu may already be installed by default, on the other hand maybe not.
sudo apt-get $AQUIET -y install whiptail ccze 2>&1 | tee -a $LOGFILE
sudo update-alternatives --set newt-palette /etc/newt/palette.original 2>&1 | tee -a $LOGFILE
# Another way - Xenial should come up in upper case in $DISTRO
. /etc/os-release
OPSYS=${ID^^}

	
# test internet connection
if [[ "$(ping -c 1 23.1.68.60  | grep '100%' )" != "" ]]; then
    printl "${IRed}!!!! No internet connection available, aborting! ${IWhite}\r\n"
    exit 0
fi

DISTRO=$(/usr/bin/lsb_release -rs)
CHECK64=$(uname -m)

if [[ $OPSYS == *"UBUNTU"* ]]; then
    if [ $DISTRO != "16.04" ] ; then
        printl "${IRed}!!!! Wrong version of Ubuntu - not 16.04, aborting! ${IWhite}\r\n"
        exit 0
    fi
fi

if [[ $OPSYS != *"RASPBIAN"* ]] && [[ $OPSYS != *"DEBIAN"* ]] && [[ $OPSYS != *"UBUNTU"* ]] && [[ $OPSYS != *"DIETPI"* ]]; then
    printl "${BIRed}By the look of it, not one of the supported operating systems - aborting${BIWhite}\r\n"; exit
fi

printstatus "progress bar"
# setup a progress bar
echo "Dpkg::Progress-Fancy \"1\";" | sudo tee /etc/apt/apt.conf.d/99progressbar > /dev/null
echo "APT::Color \"1\";" | sudo tee -a /etc/apt/apt.conf.d/99progressbar > /dev/null

username="user"
userpass="password123"

adminname="admin"
adminpass="password123"

newhostname=$(hostname)

SECONDS=0

printstatus "menu"
MYMENU=$(whiptail --title "Main Non-Pi Selection" --checklist \
        "\nSelect items as required then hit OK" 31 74 24 \
        "quiet" "Quiet(er) install - untick for lots of info " ON \
        "modpass" "Mod USER(Owntracks) and ADMIN passwords" ON \
        "nodered" "Install Node-Red modules" ON \
        "flow" "Import last Node-Red flow" ON \
		"backup" "Configure Node-Red flow backup" ON \
        "domogeek" "Install Domogeek" ON \
        "qair" "Install script qualité de l'air " ON \
        "docker" "Install Docker" ON \
        "mqtt-camera-ftpd" "Install mqtt-camera-ftpd" OFF \
        "owntrack" "Install Owntrack" ON \
        "socat" "Install Socat)" ON \
        "skycon.js" "Install Skycon.js et icones meteo" OFF \
        "rgraph" "Install Rgraph" OFF \
        "node-red-icons" "Install Node-red icons" OFF \
        "addindex" "Add my  index page and some CSS" ON 3>&1 1>&2 2>&3)

printstatus "menu quiet ?"
if [[ $MYMENU != *"quiet"* ]]; then
    AQUIET=""
    NQUIET=""
fi

printstatus "menu vide"
if [[ $MYMENU == "" ]]; then
    whiptail --title "Installation Aborted" --msgbox "Cancelled as requested." 8 78
    exit
fi

cd
printstatus "new hostname"
newhostname=$(whiptail --inputbox "Enter new HOST name\nLeave the default value or select something new" 8 60 $newhostname 3>&1 1>&2 2>&3)


if [[ $MYMENU == *"modpass"* ]]; then
    
    username=$(whiptail --inputbox "Enter a USER name (example user)\nSpecifically for Owntracks users" 8 60 $username 3>&1 1>&2 2>&3)
    if [[ -z "${username// }" ]]; then
        printf "No user name given - aborting\r\n"; exit
    fi
    
    userpass=$(whiptail --passwordbox "Enter a user password" 8 60 3>&1 1>&2 2>&3)
    if [[ -z "${userpass// }" ]]; then
        printf "No user password given - aborting${BIWhite}\r\n"; exit
    fi
    
    userpass2=$(whiptail --passwordbox "Confirm user password" 8 60 3>&1 1>&2 2>&3)
    if  [ $userpass2 == "" ]; then
        printf "${BIRed}No password confirmation given - aborting${BIWhite}\r\n"; exit
    fi
    if  [ $userpass != $userpass2 ]
    then
        printf "${BIRed}Passwords don't match - aborting${BIWhite}\r\n"; exit
    fi
    
    adminname=$(whiptail --inputbox "Enter an ADMIN name (example admin)\nFor Node-Red and MQTT" 8 60 $adminname 3>&1 1>&2 2>&3)
    if [[ -z "${adminname// }" ]]; then
        printf "${BIRed}No admin name given - aborting${BIWhite}\r\n"
        exit
    fi
    
    adminpass=$(whiptail --passwordbox "Enter an admin password" 8 60 3>&1 1>&2 2>&3)
    if [[ -z "${adminpass// }" ]]; then
        printf "${BIRed}No user password given - aborting${BIWhite}\r\n"; exit
    fi
    
    adminpass2=$(whiptail --passwordbox "Confirm admin password" 8 60 3>&1 1>&2 2>&3)
    if  [ $adminpass2 == "" ]; then
        printf "${BIRed}No password confirmation given - aborting${BIWhite}\r\n"; exit
    fi
    if  [ $adminpass != $adminpass2 ]; then
        printf "${BIRed}Passwords don't match - aborting${BIWhite}\r\n"; exit
    fi
fi



if [[ $MYMENU == *"nodered"* ]]; then
	cd
	printstatus "Installing Nodes"	
	sudo npm $NQUIET install -g node-red-admin 2>&1 | tee -a $LOGFILE
	cd .node-red
	sudo rm ./package.json
	sudo wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/package.json 2>&1 | tee -a $LOGFILE
	#npm WARN deprecated node-uuid@1.4.8: Use uuid module instead
	npm uninstall --save node-uuid 2>&1 | tee -a $LOGFILE
	npm $NQUIET install uuid 2>&1 | tee -a $LOGFILE
	#npm WARN deprecated minimatch@2.0.10: Please update to minimatch 3.0.2 or higher to avoid a RegExp DoS issue
	npm update minimatch@3.0.2
	npm $NQUIET install node-red-contrib-config 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-contrib-advanced-ping 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-weather-underground 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-forecastio 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-smooth 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-openweathermap 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-contrib-owntracks 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-geofence 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-google 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-contrib-squeezebox 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-node-forecastio 2>&1 | tee -a $LOGFILE
	npm $NQUIET install node-red-contrib-advanced-ping 2>&1 | tee -a $LOGFILE
	npm $NQUIET install https://github.com/Averelll/node-red-contrib-rfxcom 2>&1 | tee -a $LOGFILE
	/usr/bin/node-red-stop 2>&1 | tee -a $LOGFILE
	/usr/bin/node-red-start & 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"flow"* ]]; then
	myflow=flows_${newhostname}.json
	echo "Import flow $myflow"
    printstatus "Import last Node-red flow"    	
	wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/node-red-flow/flows_Domobox.json -O /home/pi/.node-red/$myflow 2>&1 | tee -a $LOGFILE
fi

if [[ $MYMENU == *"backup"* ]]; then
    printstatus "Configure Node-red flow backup"
    sudo mkdir /mnt/sauvegarde  2>&1 | tee -a $LOGFILE 
	sudo chown pi:pi /mnt/sauvegarde/ | tee -a $LOGFILE
	sudo apt-get install cifs-utils -y 2>&1 | tee -a $LOGFILE
	echo "//192.168.1.50/sauvegarde /mnt/sauvegarde  cifs guest,_netdev 0 0" | sudo tee /etc/fstab > /dev/null 2>&1  | tee -a $LOGFILE
	sudo mount /mnt/sauvegarde/ 2>&1 | tee -a $LOGFILE
	git clone -q https://github.com/laurent22/rsync-time-backup | tee -a $LOGFILE
	sudo touch "/mnt/sauvegarde/Domobox/backup.marker" | tee -a $LOGFILE
	sudo crontab -l -u root > /tmp/crontabroot
	echo "0 2 * * *  if [ -d /mnt/sauvegarde/Domobox ]; then /home/pi/rsync-time-backup/rsync_tmbackup.sh /home/pi/backup-flow/ /mnt/sauvegarde/Domobox/; fi 2>&1" >> /tmp/crontabroot
	sudo crontab -u root /tmp/crontabroot
	rm /tmp/crontabroot
fi
		 

if [[ $MYMENU == *"domogeek"* ]]; then
    printstatus "Install  Domogeek"
	cd
    mkdir domogeek
    cd domogeek
    wget --no-verbose https://bootstrap.pypa.io/get-pip.py 2>&1 | tee -a $LOGFILE
    sudo python get-pip.py 2>&1 | tee -a $LOGFILE
    sudo python -m pip install web.py beautifulsoup4 icalendar requests redis 2>&1 | tee -a $LOGFILE
    sudo apt-get install redis-server -y 2>&1 | tee -a $LOGFILE
    wget --no-verbose https://github.com/guiguiabloc/api-domogeek/archive/master.zip 2>&1 | tee -a $LOGFILE
    unzip -qq master.zip
    cd api-domogeek-master
    sudo chmod +x apidomogeek.py
    sudo sed -i -e 's#listenport = "80"#listenport = "81"#g' apidomogeek.py
    sudo sed -i -e 's#localapiurl= "http://api.domogeek.fr"#localapiurl= "http://domogeek.entropialux.com"#g' apidomogeek.py
    sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/domogeek.init -O /etc/init.d/domogeek 2>&1 | tee -a $LOGFILE
    sudo chmod 755 /etc/init.d/domogeek
    sudo systemctl enable domogeek.service 2>&1 | tee -a $LOGFILE
	sudo /etc/init.d/domogeek start & 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"qair"* ]]; then
    printstatus "Install script air quality"
	cd
    sudo mkdir /var/www/html/qair/
	sudo wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/qair/qair.bash -O /var/www/html/qair/qair.bash 2>&1 | tee -a $LOGFILE
	    sudo chown -R www-data:www-data /var/www/html/qair 
	sudo chmod +x /var/www/html/qair/qair.bash
	sudo /var/www/html/qair/qair.bash 2>&1 | tee -a $LOGFILE
	sudo crontab -l -u root > /tmp/crontabroot
	echo "10 11   * * *    /var/www/html/qair/qair.bash >> /var/log/qair.log 2>&1  >> /var/log/qair.log 2>&1" >> /tmp/crontabroot
	sudo crontab -u root /tmp/crontabroot
	rm /tmp/crontabroot
	cd
fi

if [[ $MYMENU == *"docker"* ]]; then
    printstatus "Install Docker"
	cd
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D 2>&1 | tee -a $LOGFILE
	sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' 2>&1 | tee -a $LOGFILE
	sudo apt-get update
	sudo apt-get install -y docker-engine 2>&1 | tee -a $LOGFILE
	sudo systemctl status docker |head -12 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"mqtt-camera-ftpd"* ]]; then
    printstatus "Install mqtt-camera-ftpd"
	cd
	sudo docker pull stjohnjohnson/mqtt-camera-ftpd 2>&1 | tee -a $LOGFILE
	sudo docker run -d --name="mqtt-camera-ftpd" -v /opt/mqtt-camera-ftpd:/config -p 21:21 stjohnjohnson/mqtt-camera-ftpd 2>&1 | tee -a $LOGFILE
	sleep 2s
	sudo sed -i -e 's/host: mqtt/host: localhost/g' /opt/mqtt-camera-ftpd/config.yml 2>&1 | tee -a $LOGFILE
	sudo useradd --password `openssl passwd -1 bipbip14` camera 2>&1 | tee -a $LOGFILE
	sudo docker restart mqtt-camera-ftpd 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"owntrack"* ]]; then
    printstatus "Install Owntrack"
	cd
	mkdir owntrack
	cd owntrack
	curl http://repo.owntracks.org/repo.owntracks.org.gpg.key | sudo apt-key add - 2>&1 | tee -a $LOGFILE
	echo "deb [arch=amd64]  http://repo.owntracks.org/debian jessie main" | sudo tee /etc/apt/sources.list.d/owntracks.list > /dev/null
	sudo apt-get update
	wget http://launchpadlibrarian.net/206707239/libsodium13_1.0.3-1_amd64.deb 2>&1 | tee -a $LOGFILE
	sudo apt-get install ./libsodium13_1.0.3-1_amd64.deb 2>&1 | tee -a $LOGFILE
	sudo apt-get install -y libsodium-dev 2>&1 | tee -a $LOGFILE
	sudo apt-get install -y ot-recorder 2>&1 | tee -a $LOGFILE
	sudo sed -i -e 's#\# OTR_USER=""#OTR_USER="admin"#g' /etc/default/ot-recorder
	sudo sed -i -e 's/\# OTR_PASS=""/OTR_PASS="'"$adminpass"'"/g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_GEOKEY=""#OTR_GEOKEY="AIzaSyBCdi1b88QSDL_eUK9R7lK8VPN0rbri1ko"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_BROWSERAPIKEY=""#OTR_BROWSERAPIKEY="AIzaSyBCdi1b88QSDL_eUK9R7lK8VPN0rbri1ko"#g' /etc/default/ot-recorder
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/local -O /etc/rc.local 2>&1 | tee -a $LOGFILE
    sudo chmod 755  /etc/rc.local
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/ot-recorder.conf  -O  /etc/apache2/conf-available/ot-recorder.conf  2>&1 | tee -a $LOGFILE
	sudo /usr/sbin/ot-recorder 'owntracks/#' & 2>&1 | tee -a $LOGFILE
	sudo /usr/sbin/a2enmod proxy_http 2>&1 | tee -a $LOGFILE
	sudo /usr/sbin/a2enmod proxy_wstunnel 2>&1 | tee -a $LOGFILE
	sudo /usr/sbin/a2enmod proxy_html 2>&1 | tee -a $LOGFILE
	sudo /usr/sbin/a2enconf ot-recorder 2>&1 | tee -a $LOGFILE
	sudo /etc/init.d/apache2 restart 2>&1 | tee -a $LOGFILE
	sudo mosquitto_passwd -b /etc/mosquitto/passwords poirier $adminpass
	sudo mosquitto_passwd -b /etc/mosquitto/passwords HP $userpass
	sudo mosquitto_passwd -b /etc/mosquitto/passwords CP $userpass
	sudo /etc/init.d/mosquitto restart 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"socat"* ]]; then
    printstatus "Install Socat"
	cd
	sudo apt-get install socat 2>&1 | tee -a $LOGFILE
	sudo wget -O /etc/remote-tty.conf https://raw.githubusercontent.com/NicolasBernaerts/debian-scripts/master/remote-tty/remote-tty.conf 2>&1 | tee -a $LOGFILE
	sudo wget -O /usr/local/bin/remote-tty https://raw.githubusercontent.com/NicolasBernaerts/debian-scripts/master/remote-tty/remote-tty 2>&1 | tee -a $LOGFILE
	sudo chmod +x /usr/local/bin/remote-tty
	echo "192.168.1.254;1001;ttyUSB0" | sudo tee /etc/remote-tty.conf > /dev/null
	sudo sed -i -e 's#link=/dev/${LOCAL_TTY}#link=/dev/${LOCAL_TTY},mode=666,group=dialout#g' /usr/local/bin/remote-tty
	sudo crontab -l -u root > /tmp/crontabroot
	echo "0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/bin/remote-tty  >> /var/log/remote-tty.log 2>&1" >> /tmp/crontabroot
	sudo crontab -u root /tmp/crontabroot
	rm /tmp/crontabroot
	cd
fi

if [[ $MYMENU == *"skycon.js"* ]]; then
    printstatus "Install Skycon.js"
    cd
    mkdir /usr/lib/node_modules/node-red/public/myjs
    cd /usr/lib/node_modules/node-red/public/myjs
    wget https://raw.githubusercontent.com/maxdow/skycons/master/skycons.js 2>&1 | tee -a $LOGFILE
    wget https://canvas-gauges.com/download/latest/all/gauge.min.js 2>&1 | tee -a $LOGFILE
    cd
fi

if [[ $MYMENU == *"rgraph"* ]]; then
    printstatus "Install Rgraph"
    cd
	mkdir Rgraph
    cd Rgraph
	wget https://www.rgraph.net/downloads/RGraph4.62-stable.zip 2>&1 | tee -a $LOGFILE
	unzip -qq RGraph4.62-stable.zip 2>&1 | tee -a $LOGFILE
	cd RGraph/libraries/
	mkdir /usr/lib/node_modules/node-red/public/myjs/RGraph
	cp * /usr/lib/node_modules/node-red/public/myjs/RGraph/ 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"node-red-icon"* ]]; then
    printstatus "Install Node-Red Icons"
    cd
	wget https://raw.githubusercontent.com/coyotte14/Domobox/master/icones.tgz  2>&1 | tee -a $LOGFILE
	sudo tar xfz icones.tgz -C /var/www/html/ 2>&1 | tee -a $LOGFILE
	cd
fi

if [[ $MYMENU == *"addindex"* ]]; then
    printstatus "Install My HTTP index file"
    cd
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/index.html  -O /var/www/html/index.html 2>&1 | tee -a $LOGFILE
	cd
fi

sudo apt-get $AQUIET -y clean 2>&1 | tee -a $LOGFILE

myip=$(hostname -I)
thehostname=$(hostname)
echo $newhostname | sudo tee /etc/hostname > /dev/null 2>&1
sudo sed -i '/^127.0.1.1/ d' /etc/hosts > /dev/null 2>&1
echo 127.0.1.1 $newhostname | sudo tee -a /etc/hosts > /dev/null 2>&1
sudo /etc/init.d/hostname.sh > /dev/null 2>&1


printstatus "All done."
printf 'When you are happy, remove the script from the /home/pi directory.\r\n'
printf 'Current IP: %s  Hostname: %s\r\n' "$myip" "$thehostname"
echo -e Current IP: $myip  Hostname: $thehostname >> $LOGFILE
printstatus  "ALL DONE - PLEASE REBOOT NOW THEN TEST"