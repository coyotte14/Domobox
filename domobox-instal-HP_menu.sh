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
        "nodered" "Install Node-Red modules" ON \
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

if [[ $MYMENU == *"nodered"* ]]; then
    echo "Install node-red modules"
	cd	
	sudo npm install -g node-red-admin
	cd .node-red
	sudo rm ./package.json
	sudo wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/package.json
	#npm WARN deprecated node-uuid@1.4.8: Use uuid module instead
	npm uninstall --save node-uuid
	npm install uuid
	#npm WARN deprecated minimatch@2.0.10: Please update to minimatch 3.0.2 or higher to avoid a RegExp DoS issue
	npm update minimatch@3.0.2
	npm install node-red-contrib-config
	npm install node-red-contrib-advanced-ping
	npm install node-red-node-weather-underground
	npm install node-red-node-forecastio
	npm install node-red-node-smooth
	npm install node-red-node-openweathermap
	npm install node-red-contrib-owntracks
	npm install node-red-node-geofence
	npm install node-red-node-google
	npm install node-red-contrib-squeezebox
	npm install node-red-node-forecastio
	npm install node-red-contrib-advanced-ping
	npm install https://github.com/Averelll/node-red-contrib-rfxcom
	/usr/bin/node-red-stop
	/usr/bin/node-red-start &
	cd
fi


if [[ $MYMENU == *"domogeek"* ]]; then
    printstatus "Install  Domogeek"
	cd
    mkdir domogeek
    cd domogeek
    wget --no-verbose https://bootstrap.pypa.io/get-pip.py
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
	sudo /etc/init.d/domogeek start
	cd
fi

if [[ $MYMENU == *"qair"* ]]; then
    printstatus "Install script air quality"
	cd
	mkdir qair
	cd qair
    wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/qair/qair.bash
	wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/qair/qair.crontab
    sudo cp -R ../qair /var/www/html/qair
    sudo chown -R www-data:www-data /var/www/html/qair
    sudo cp qair.crontab /etc/cron.d/qair.crontab
	sudo chmod +x /var/www/html/qair/qair.bash
	sudo /var/www/html/qair/qair.bash
	cd
fi

if [[ $MYMENU == *"docker"* ]]; then
    printstatus "Install Docker"
	cd
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
	sudo apt-get update
	sudo apt-get install -y docker-engine
	sudo systemctl status docker |head -12
	cd
fi

if [[ $MYMENU == *"mqtt-camera-ftpd"* ]]; then
    printstatus "Install mqtt-camera-ftpd"
	cd
	sudo docker pull stjohnjohnson/mqtt-camera-ftpd
	sudo docker run -d --name="mqtt-camera-ftpd" -v /opt/mqtt-camera-ftpd:/config -p 21:21 stjohnjohnson/mqtt-camera-ftpd
	sleep 2s
	sudo sed -i -e 's/host: mqtt/host: localhost/g' /opt/mqtt-camera-ftpd/config.yml
	sudo useradd --password `openssl passwd -1 bipbip14` camera
	sudo docker restart mqtt-camera-ftpd
	cd
fi

if [[ $MYMENU == *"owntrack"* ]]; then
    printstatus "Install Owntrack"
	cd
	mkdir owntrack
	cd owntrack
	curl http://repo.owntracks.org/repo.owntracks.org.gpg.key | sudo apt-key add -
	echo "deb [arch=amd64]  http://repo.owntracks.org/debian jessie main" | sudo tee /etc/apt/sources.list.d/owntracks.list > /dev/null
	sudo apt-get update
	wget http://launchpadlibrarian.net/206707239/libsodium13_1.0.3-1_amd64.deb
	sudo apt-get install ./libsodium13_1.0.3-1_amd64.deb
	sudo apt-get install -y libsodium-dev
	sudo apt-get install -y ot-recorder
	sudo sed -i -e 's#\# OTR_USER=""#OTR_USER="admin"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_PASS=""#OTR_PASS="huup6380!"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_GEOKEY=""#OTR_GEOKEY="AIzaSyBCdi1b88QSDL_eUK9R7lK8VPN0rbri1ko"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_BROWSERAPIKEY=""#OTR_BROWSERAPIKEY="AIzaSyBCdi1b88QSDL_eUK9R7lK8VPN0rbri1ko"#g' /etc/default/ot-recorder
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/local -O /etc/rc.local
    sudo chmod 755  /etc/rc.local
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/ot-recorder.conf  -O  /etc/apache2/conf-available/ot-recorder.conf 
	sudo /usr/sbin/ot-recorder 'owntracks/#' &
	sudo /usr/sbin/a2enmod proxy_http
	sudo /usr/sbin/a2enmod proxy_wstunnel
	sudo /usr/sbin/a2enmod proxy_html
	sudo /usr/sbin/a2enconf ot-recorder
	sudo /etc/init.d/apache2 restart
	sudo mosquitto_passwd -b /etc/mosquitto/passwords poirier huup6380!
	sudo mosquitto_passwd -b /etc/mosquitto/passwords HP huup6380!
	sudo mosquitto_passwd -b /etc/mosquitto/passwords CP huup6380!
	sudo /etc/init.d/mosquitto restart
	cd
fi

if [[ $MYMENU == *"socat"* ]]; then
    printstatus "Install Socat"
	cd
	sudo apt-get install socat
	sudo wget -O /etc/remote-tty.conf https://raw.githubusercontent.com/NicolasBernaerts/debian-scripts/master/remote-tty/remote-tty.conf
	sudo wget -O /usr/local/bin/remote-tty https://raw.githubusercontent.com/NicolasBernaerts/debian-scripts/master/remote-tty/remote-tty
	sudo chmod +x /usr/local/bin/remote-tty
	echo "192.168.1.254;1001;ttyUSB0" | sudo tee /etc/remote-tty.conf > /dev/null
	sudo sed -i -e 's#link=/dev/${LOCAL_TTY}#link=/dev/${LOCAL_TTY},mode=666,group=dialout#g' /usr/local/bin/remote-tty
	sudo crontab -l -u root > /tmp/crontabroot
	echo "*/5 * * * * root /usr/local/bin/remote-tty" >> /tmp/crontabroot
	sudo crontab -u root /tmp/crontabroot
	rm /tmp/crontabroot
	cd
fi

if [[ $MYMENU == *"skycon.js"* ]]; then
    printstatus "Install Skycon.js"
    cd
    mkdir /usr/lib/node_modules/node-red/public/myjs
    cd /usr/lib/node_modules/node-red/public/myjs
    wget https://raw.githubusercontent.com/maxdow/skycons/master/skycons.js
    wget https://canvas-gauges.com/download/latest/all/gauge.min.js
    cd
fi

if [[ $MYMENU == *"rgraph"* ]]; then
    printstatus "Install Rgraph"
    cd
	mkdir Rgraph
    cd Rgraph
	wget https://www.rgraph.net/downloads/RGraph4.62-stable.zip
	unzip RGraph4.62-stable.zip
	cd RGraph/libraries/
	mkdir /usr/lib/node_modules/node-red/public/myjs/RGraph
	cp * /usr/lib/node_modules/node-red/public/myjs/RGraph/
	cd
fi

if [[ $MYMENU == *"node-red-icon"* ]]; then
    printstatus "Install Node-Red Icons"
    cd
	wget https://raw.githubusercontent.com/coyotte14/Domobox/master/icones.tgz 
	sudo tar xvfz icones.tgz -C /var/www/html/
	cd
fi

if [[ $MYMENU == *"addindex"* ]]; then
    printstatus "Install My HTTP index file"
    cd
	mkdir httpd
    cd httpd
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/index.html  -O /var/www/html/index.html
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

exit

# =============================================================================================
task_start "Install Node-Red modules?" "Installing Node-Red modules"
if [ $skip -eq 0 ]; then
	cd	
	sudo npm install -g node-red-admin
	cd .node-red
	sudo rm ./package.json
	sudo wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/package.json
	npm install node-red-contrib-config
	npm install node-red-contrib-advanced-ping
	npm install node-red-node-weather-underground
	npm install node-red-node-forecastio
	npm install node-red-node-smooth
	npm install node-red-node-openweathermap
	npm install node-red-contrib-owntracks
	npm install node-red-node-geofence
	npm install node-red-node-google
	npm install node-red-contrib-squeezebox
	npm install node-red-node-forecastio
	npm install node-red-contrib-advanced-ping
	npm install https://github.com/Averelll/node-red-contrib-rfxcom
	/usr/bin/node-red-stop
	/usr/bin/node-red-start
	cd
	echo "mytrace" >> $mytrace 
	task_end
fi

# =============================================================================================
task_start "Install Domogeek?" "Installing Domogeek"
if [ $skip -eq 0 ]; then
	cd
    mkdir domogeek
    cd domogeek
    wget --no-verbose https://bootstrap.pypa.io/get-pip.py
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
	sudo /etc/init.d/domogeek start
	cd
	echo "Domogeek" >> $mytrace
	task_end
fi

# =============================================================================================
task_start "Install Script qualite de l'air?" "Installing Qualite de l'air"
if [ $skip -eq 0 ]; then
	cd
	mkdir qair
	cd qair
    wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/qair/qair.bash
	wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/qair/qair.crontab
    sudo cp -R ../qair /var/www/html/qair
    sudo chown -R www-data:www-data /var/www/html/qair
    sudo cp qair.crontab /etc/cron.d/qair.crontab
	sudo chmod +x /var/www/html/qair/qair.bash
	sudo /var/www/html/qair/qair.bash
	cd
	echo "qair" >> $mytrace
	task_end
fi

# =============================================================================================
task_start "Install Docker ?" "Installing Docker"
if [ $skip -eq 0 ]; then
	cd
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
	sudo apt-get update
	sudo apt-get install -y docker-engine
	sudo systemctl status docker |head -12
	cd
	echo "Docker" >> $mytrace
	task_end
fi

# =============================================================================================
task_start "Install Docker mqtt-camera-ftpd ?" "Installing Docker mqtt-camera-ftpd"
if [ $skip -eq 0 ]; then
	cd
	sudo docker pull stjohnjohnson/mqtt-camera-ftpd
	sudo docker run -d --name="mqtt-camera-ftpd" -v /opt/mqtt-camera-ftpd:/config -p 21:21 stjohnjohnson/mqtt-camera-ftpd
	sleep 2s
	sudo sed -i -e 's/host: mqtt/host: localhost/g' /opt/mqtt-camera-ftpd/config.yml
	sudo useradd --password `openssl passwd -1 bipbip14` camera
	sudo docker restart mqtt-camera-ftpd
	cd
	echo "mqtt-camera-ftpd" >> $mytrace
	task_end
	# sed: impossible de lire /opt/mqtt-camera-ftpd/config.yml: Aucun fichier ou dossier de ce type
fi

# =============================================================================================
task_start "Install Owntrack ?" "Installing Owntrack"
if [ $skip -eq 0 ]; then
	cd
	mkdir owntrack
	cd owntrack
	curl http://repo.owntracks.org/repo.owntracks.org.gpg.key | sudo apt-key add -
	echo "deb [arch=amd64]  http://repo.owntracks.org/debian jessie main" | sudo tee /etc/apt/sources.list.d/owntracks.list > /dev/null
	sudo apt-get update
	wget http://launchpadlibrarian.net/206707239/libsodium13_1.0.3-1_amd64.deb
	sudo apt-get install ./libsodium13_1.0.3-1_amd64.deb
	sudo apt-get install -y libsodium-dev
	sudo apt-get install -y ot-recorder
	sudo sed -i -e 's#\# OTR_USER=""#OTR_USER="admin"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_PASS=""#OTR_PASS="huup6380!"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_GEOKEY=""#OTR_GEOKEY="AIzaSyBCdi1b88QSDL_eUK9R7lK8VPN0rbri1ko"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_BROWSERAPIKEY=""#OTR_BROWSERAPIKEY="AIzaSyBCdi1b88QSDL_eUK9R7lK8VPN0rbri1ko"#g' /etc/default/ot-recorder
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/local -O /etc/rc.local
    sudo chmod 755  /etc/rc.local
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/ot-recorder.conf  -O  /etc/apache2/conf-available/ot-recorder.conf 
	sudo /usr/sbin/ot-recorder 'owntracks/#' &
	sudo /usr/sbin/a2enmod proxy_http
	sudo /usr/sbin/a2enmod proxy_wstunnel
	sudo /usr/sbin/a2enmod proxy_html
	sudo /usr/sbin/a2enconf ot-recorder
	sudo /etc/init.d/apache2 restart
	sudo mosquitto_passwd -b /etc/mosquitto/passwords poirier huup6380!
	sudo mosquitto_passwd -b /etc/mosquitto/passwords HP huup6380!
	sudo mosquitto_passwd -b /etc/mosquitto/passwords CP huup6380!
	sudo /etc/init.d/mosquitto restart
	cd
	echo "Owntrack" >> $mytrace
	task_end
fi

# =============================================================================================
task_start "Install socat ?" "Installing socat"
if [ $skip -eq 0 ]; then
	cd
	sudo apt-get install socat
	sudo wget -O /etc/remote-tty.conf https://raw.githubusercontent.com/NicolasBernaerts/debian-scripts/master/remote-tty/remote-tty.conf
	sudo wget -O /usr/local/bin/remote-tty https://raw.githubusercontent.com/NicolasBernaerts/debian-scripts/master/remote-tty/remote-tty
	sudo chmod +x /usr/local/bin/remote-tty
	echo "192.168.1.254;1001;ttyUSB0" | sudo tee /etc/remote-tty.conf > /dev/null
	sudo sed -i -e 's#link=/dev/${LOCAL_TTY}#link=/dev/${LOCAL_TTY},mode=666,group=dialout#g' /usr/local/bin/remote-tty
	sudo crontab -l -u root > /tmp/crontabroot
	echo "*/5 * * * * root /usr/local/bin/remote-tty" >> /tmp/crontabroot
	sudo crontab -u root /tmp/crontabroot
	rm /tmp/crontabroot
	cd
	echo "socat" >> $mytrace
	task_end
fi

# =============================================================================================
task_start "Install Skycon.js and icons for node-red meteo?" "Installing Skycons"
if [ $skip -eq 0 ]; then
    cd
    mkdir /usr/lib/node_modules/node-red/public/myjs
    cd /usr/lib/node_modules/node-red/public/myjs
    wget https://raw.githubusercontent.com/maxdow/skycons/master/skycons.js
    wget https://canvas-gauges.com/download/latest/all/gauge.min.js
    cd
	echo "socat" >> $mytrace
    task_end
	
fi


# =============================================================================================
task_start "Install Rgraph?" "Installing Rgraph"
if [ $skip -eq 0 ]; then
    cd
	mkdir Rgraph
    cd Rgraph
	wget https://www.rgraph.net/downloads/RGraph4.62-stable.zip
	unzip RGraph4.62-stable.zip
	cd RGraph/libraries/
	mkdir /usr/lib/node_modules/node-red/public/myjs/RGraph
	cp * /usr/lib/node_modules/node-red/public/myjs/RGraph/
	cd
	echo "Rgraph" >> $mytrace
    task_end
fi

# =============================================================================================
task_start "Install Icones Node-red?" "Installing icones node-red"
if [ $skip -eq 0 ]; then
    cd
	wget https://raw.githubusercontent.com/coyotte14/Domobox/master/icones.tgz 
	sudo tar xvfz icones.tgz -C /var/www/html/
	cd
	echo "Icones" >> $mytrace
    task_end
fi

# =============================================================================================
task_start "Install My index HTTP?" "Installing My index HTTP"
if [ $skip -eq 0 ]; then
    cd
	mkdir httpd
    cd httpd
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/index.html  -O /var/www/html/index.html
	cd
	echo "index" >> $mytrace
    task_end
fi