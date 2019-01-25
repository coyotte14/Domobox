#!/bin/bash
#
# ne pas nommer le script socat-xxx car il se kill lui même !!
# script renommé soca-restart.sh
#
echo "redémarrage de socat"
sudo kill -15 `ps -edf | grep socat | grep -v grep | awk '{print $2}'` > /dev/null 2>&1
sudo /usr/local/bin/remote-tty
echo "socat redémarré !"
