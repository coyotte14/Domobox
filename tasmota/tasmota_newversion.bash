#!/bin/bash

##########################################################################
### Script de comparaison version Tasmota installée et disponible en ligne
###
### Utilisation
### tasmota_newversion.bash
###  false : pas de nouvelle version en ligne
###  true : nouvelle version en ligne
###
##########################################################################
#
### Configuration
Tasmotadir="/home/pi/tasmota"
txtfile="$Tasmotadir/tasmota.txt"
DEBUG=false
DEBUG=true
#
### End Configuration
##########################################################################
#
TasmotaCurrent=`curl -s http://192.168.1.72/cm?cmnd=status%202 | cut -d '"' -f6`
#
TasmotaLatest=`curl -s https://github.com/arendst/Sonoff-Tasmota/releases/latest | cut -d '"' -f2 | rev | cut -d'/' -f1 | rev | sed 's/.\{1\}//'`
#
if [ "$TasmotaCurrent" = "$TasmotaLatest" ]
then
        newversion="false"
else
        newversion="true"
fi
# txt file
echo -n $newversion > $txtfile
#sudo cp  $txtfile /mnt/sharenfs/temp/
#
##########################################################################"
###debug
if [ "$DEBUG" = "true" ]
then
        echo "-----------------------------"
        debugdate=$(date +%Y%m%d-%H:%M:%S)
        echo "$debugdate Informations debug"
        echo "TasmotaCurrent : $TasmotaCurrent"
        echo "TasmotaLatest : $TasmotaLatest"
        echo "nouvelle version ? : $newversion"
        echo "-----------------------------"
fi
##########################################################################"
### Fin traitement
