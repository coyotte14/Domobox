#!/bin/bash
 
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

skip=0
other=0
 
clean_stdin()
{
while read -r -t 0; do
    read -n 256 -r -s
done
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


# =============================================================================================
task_start "Install Node-Red modules?" "Installing Node-Red modules"
if [ $skip -eq 0 ]; then
	cd
	sudo npm install -g node-red-admin
	cd .node-red
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
	npm install https://github.com/Averelll/node-red-contrib-rfxcom
	cd
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
	cd
	task_end
fi

# =============================================================================================
task_start "Install Script qualite de l'air?" "Installing Qualit� de l'air"
if [ $skip -eq 0 ]; then
	cd
	mkdir air
	cd air
    wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/air.tgz
	wget --no-verbose https://raw.githubusercontent.com/coyotte14/Domobox/master/air.crontab
    sudo tar xfz air.tgz -C /var/www/html
    sudo chown -R www-data:www-data /var/www/html/air
    sudo cp air.crontab /etc/cron.d/air.crontab
	cd
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
	sudo systemctl status docker
	cd
	task_end
fi

# =============================================================================================
task_start "Install Docker mqtt-camera-ftpd ?" "Installing Docker mqtt-camera-ftpd"
if [ $skip -eq 0 ]; then
	cd
	sudo docker pull stjohnjohnson/mqtt-camera-ftpd
	sudo docker run -d --name="mqtt-camera-ftpd" -v /opt/mqtt-camera-ftpd:/config -p 21:21 stjohnjohnson/mqtt-camera-ftpd
	sudo sed -i -e 's/host: mqtt/host: localhost/g' /opt/mqtt-camera-ftpd/config.yml
	sudo useradd --password `openssl passwd -1 bipbip14` camera
	sudo docker restart mqtt-camera-ftpd
	cd
	task_end
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
	sudo apt-get install libsodium-dev
	sudo apt-get install ot-recorder
	sudo sed -i -e 's#\# OTR_USER=""#OTR_USER="admin"#g' /etc/default/ot-recorder
	sudo sed -i -e 's#\# OTR_PASS=""#OTR_PASS="huup6380!"#g' /etc/default/ot-recorder
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/local -O /etc/rc.local
    	sudo chmod 755  /etc/rc.local
	sudo wget https://raw.githubusercontent.com/coyotte14/Domobox/master/Owntracks/ot-recorder.conf  -O ot-recorder.conf 
	sudo /usr/sbin/ot-recorder 'owntracks/#' &
	sudo /usr/sbin/a2enmod proxy_http
	sudo /usr/sbin/a2enmod proxy_wstunnel
	sudo /usr/sbin/a2enmod proxy_html
	sudo /etc/init.d/apache2 restart
	cd
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
    task_end
fi

# =============================================================================================
task_start "Install Icones Node-red?" "Installing icones node-red"
if [ $skip -eq 0 ]; then
    cd
	wget https://raw.githubusercontent.com/coyotte14/Domobox/master/icones.tgz 
	sudo tar xvfz icones.tgz -C /var/www/html/
	cd
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
    task_end
fi