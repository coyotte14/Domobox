#!/bin/bash

##########################################################################
### Script d'extraction de l'indice UV depuis :
### http://wxdata.weather.com/wxdata/weather/local/FRXX3167?cc=*&unit=m
### code ville Saint Contest : FRXX3167
###
### Utilisation
### Creation d'un fichier uv.txt comprenant la valeur uv en cours, mise a jour toutes 30mn en tache cron
### MQTT publist sur uv/value  et uv/lastupdate
###
### configuration crontab user pi
### # Indice UV toutes les 30mn
### 5,35 * * * * /home/pi/uv/uv-extract-publish.bash #Indice UV
###
##########################################################################

##########################################################################
### Configuration
#
uvDir="/home/pi/uv"
tmpFile=$uvDir/uv.tmp
uvFile=$uvDir/uv.txt
logFile="/var/log/uv.log"
#
mqttHost="localhost"
mqttPublish="/usr/bin/mosquitto_pub"
mqttUser="mqtt"
mqttPwd="mqtt6380"
mqttTopicUvValue="uv/value"
mqttTopicUvlastupdate="uv/lastupdate"
#
### End Configuration
##########################################################################

### Fichier  meteo avec indice UV
date=`date +%d-%m-%Y`
dateHeure=`date +%d-%m-%Y-%H:%M:%S`
curl -s "http://wxdata.weather.com/wxdata/weather/local/FRXX3167?cc=*&unit=m" > $tmpFile

##########################################################################
### recherhce indice UV  <i>n</i>
###
uvInd=$(grep -o '<i>'".*"  $tmpFile |  sed 's/<i>//g' | sed 's/<\/i>//g')
rm $tmpFile
if [ -z  $uvInd ]
then
	# erreur
	echo "$dateHeure - Erreur - indice UV non trouve" >> $logFile
	exit
fi
#
# creation fichier texte indice UV
echo $uvInd > $uvFile
echo "$dateHeure - Indice UV : $uvInd" >> $logFile
#
# MQTT publish indice UV et dat Upadte
$mqttPublish -u $mqttUser -P $mqttPwd -t $mqttTopicUvValue -m $uvInd
$mqttPublish -u $mqttUser -P $mqttPwd -t $mqttTopicUvlastupdate -m $dateHeure
