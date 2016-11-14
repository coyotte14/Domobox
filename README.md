# Domobox

Installation Domobox :
Sur Raspberry 3 en Rasbian :
sudo apt-get update
Se connecter sur le compte pi
Dans le répertoire Home pi (/home/pi) :
 chmod +x domobox-instal.sh 
 ./domobox-instal.sh 

Contenu de l'installation :
Installation du serveur Web  Apache port http://domobox:80, page d'accueil avec accès aux logiciels disponibles sur Domobox
Installation du broker MQTT Mosquitto port 1883
Installation de Node-Red, environnement de développement visuel pour l’Internet des Objets. 
- Node-Red Control Panel : http://domobox:1883
- Node-Red Dashboard : http://domobox:1883/ui
Installation de l'interface web d'administration linux Webmin : http://domobox:10000
Installation de Netdata, interface de monitoring performance temps réel
Installation de SQLlite + SQLlite manager : http://domobox/phpliteadmin
Installation de la page Web PhpSysInfo, pour d'afficher des informations concernant le système et le matériel : http://domobox/phpsysinfo

Ressources :
Installation du script "Qualité de l'air" : voir http://www.domo-blog.fr/lindice-de-pollution-de-lair-dans-votre-eedomus/
Installation de l'API Domogeek en local : voir http://domogeek.entropialux.com/static/index.html
Installation du script "Précipitation dans l'heure" : voir 
Mise à disposition de flow Node-Red : https://github.com/coyotte14/Domobox/edit/master/

