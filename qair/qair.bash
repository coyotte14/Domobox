#!/bin/bash

##########################################################################"
### Script d'extraction de la qualité de l'air à partir du site :
### http://www.lcsqa.org/indices-qualite-air/liste/jour
### Publication journalière de la prévision de qualité de l'air du jour pour
### plus de 100 villes françaises
###
### Utilisation
### qair.bash
###	sans paramètre, utilise la ville par défaut configurée dans les paramètres ci-dessous
###
### qair.bash Calais
###	qualité de l'air pour la ville de Calais
###
### Fichiers générés en sortie
### 	/var/www.html/air/qair.txt
###		contient uniquement l'indice de qualité de l'air de la ville
###
### 	/var/www.html/air/qair.json
###		contient toutes les informations qualité de l'air de la ville au format json
###		exemple pour la ville de Calais :
###		{"date":"2017-06-06","ville":"CALAIS","qualite-air":3,"niveau":"Bon","O3":3,"NO2":1,"PM10":2}
###
### 	/var/www.html/air/qair.xml
###		contient toutes les informations qualité de l'air de la ville au format xml
###		exemple pour la ville de Calais :
###		<?xml version="1.0" encoding="ISO-8859-1" ?>
###		<data>
###		<date>2017-06-06</date>
###		<ville>CALAIS</ville>
###		<niveau>Bon</niveau>
###		<indice>3</indice>
###		<O3>3</O3>
###		<NO2>1</NO2>
###		<PM10>2</PM10>
###		</data>
###
### 	/var/www.html/air/qairville.txt
###	liste des villes comportant des données qualité de l'air
###
##########################################################################"

##########################################################################"
### Configuration
tmpfile="indices-qualite-air.tmp"
airdir="/var/www/html/qair"
jsonfile="$airdir/qair.json"
txtfile="$airdir/qair.txt"
xmlfile="$airdir/qair.xml"
villefile="$airdir/qairville.txt"
villedefaut="CAEN"
DEBUG=false
#DEBUG=true
### End Configuration
##########################################################################"

##########################################################################"
### Paramètres
if [ "$#" -gt 1 ]; then
	echo "Erreur : 1 seul argument possible, le nom d'une ville"
	exit
fi
if [ "$#" -eq 0 ]; then
	#echo "Pas de paramètres :  ville par défaut $villedefaut"
	ville=$villedefaut
fi
##########################################################################"

##########################################################################"
### Fichier des indices qualité de l'air prévu ce jour. Publié chaque jour à 11H
date=`date +%Y-%m-%d`
curl -L -s "http://www.lcsqa.org/indices-qualite-air/liste/jour" > $tmpfile

##########################################################################"
### Construire Fichier des villes
ligneville=$(grep -n "<tbody>" $tmpfile  | cut -d: -f1)
lignevilleend=$(grep -n "</tbody>" $tmpfile  | cut -d: -f1)
#echo $ligneville
#echo $lignevilleend
pas1=4
pas2=13
ligneville=`expr $ligneville + $pas1`
findville=`sed -n "${ligneville}p" $tmpfile | sed 's/<td>//g' | sed 's/<\/td>//g' | sed 's/ //g'`
echo $findville > $villefile

while [ $ligneville -lt $lignevilleend ]; do
	ligneville=`expr $ligneville + $pas2`
	findville=`sed -n "${ligneville}p" $tmpfile | sed 's/<td>//g' | sed 's/<\/td>//g' | sed 's/ //g'`
	len=${#findville}
	if [ $len -gt 0 ]
	then
		echo $findville >> $villefile
		#echo $findville
	fi
done

##########################################################################"
### Ville passée en parmètre existe t'elle sur  www.lcsqa.org
if [ "$#" -eq 1 ]; then
	# ^^ passe le variable en majuscule
	# le mot doit être exactement celui passé en paraètre, entouré de ^ et $
	if grep -q "^${1^^}$" $villefile
	then
		echo "OK : ville  ${1^^} trouvée"
		ville=${1^^}
	else
		echo "Erreur : ville $1 non trouvée."
		echo "Vérifiez sur http://www.lcsqa.org/indices-qualite-air/liste/jour"
		exit
	fi
fi
##########################################################################"
### Trouver l'emplacement de la ville dans le fichier
maligne=$(grep -n $ville  $tmpfile | cut -d: -f1)
#echo $maligne

# indice qualité de l'air : 1 ligne plus bas
maligne=`expr $maligne + 1`
indice=`sed -n "${maligne}p" $tmpfile | sed 's/<td>//g' | sed 's/<\/td>//g' | sed 's/ //g'`

# indice O3 : 1 ligne plus bas
maligne=`expr $maligne + 1`
o3=`sed -n "${maligne}p" $tmpfile | sed 's/<td>//g' | sed 's/<\/td>//g' | sed 's/ //g'`

# indice NO2 : 1 ligne plus bas
maligne=`expr $maligne + 1`
no2=`sed -n "${maligne}p" $tmpfile | sed 's/<td>//g' | sed 's/<\/td>//g' | sed 's/ //g'`

# indice PM10 : 1 ligne plus bas
maligne=`expr $maligne + 1`
pm10=`sed -n "${maligne}p" $tmpfile | sed 's/<td>//g' | sed 's/<\/td>//g' | sed 's/ //g'`

##########################################################################"
### Niveau pollution
#   1 et 2 : Très bon
#   3 et 4 : Bon
#   5 : Moyen
#   6 et 7  : Médiocre
#   8 et 9 : Mauvais
#   10 : Très mauvais

case "$indice" in
        1)
            niveau="Très bon"
            ;;
         
        2)
            niveau="Très bon"
            ;;
         
        3)
            niveau="Bon"
            ;;
        4)
            niveau="Bon"
            ;;
        5)
            niveau="Moyen"
            ;;
         
        6)
            niveau="Médiocre"
            ;;
        7)
            niveau="Médiocre"
            ;;
        8)
            niveau="Mauvais"
            ;;
        9)
            niveau="Mauvais"
            ;;
        10)
            niveau="Très mauvais"
            ;;
        *)
            debugdate=$(date +%Y%m%d-%H:%M:%S)
			echo "$debugdate  Erreur: indice pollution non trouvé"
            exit 1
esac

##########################################################################"
### json file
#json="{\"date\":\"""$date"\",\"ville\":\""$ville"\",\"qualite-air\":"$indice",\"O3\":"$o3,\"NO2\":"$no2",\"PM10\":"$pm10"}"
json="{\"date\":\"""$date"\",\"ville\":\""$ville"\",\"qualite-air\":"$indice",\"niveau\":\""$niveau"\",\"O3\":"$o3,\"NO2\":"$no2",\"PM10\":"$pm10"}"
echo $json > $jsonfile

##########################################################################"
### txt file
echo $indice > $txtfile

##########################################################################"
###xml file
echo "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" > $xmlfile
echo "<data>" >> $xmlfile
echo "<date>$date</date>" >> $xmlfile
echo "<ville>$ville</ville>" >> $xmlfile
echo "<niveau>$niveau</niveau>" >> $xmlfile
echo "<indice>$indice</indice>" >> $xmlfile
echo "<O3>$o3</O3>" >> $xmlfile
echo "<NO2>$no2</NO2>" >> $xmlfile
echo "<PM10>$pm10</PM10>" >> $xmlfile
echo "</data>" >> $xmlfile

##########################################################################"
###debug
if [ "$DEBUG" = "true" ]
then
	echo "-----------------------------"
	debugdate=$(date +%Y%m%d-%H:%M:%S)
	echo "$debugdate Informations debug"
	echo "ville : " $ville
	echo "date : " $date
	echo "indice pollution : " $indice
	echo "indice QO3 : " $o3
	echo "indice NO2 : " $no2
	echo "indice PM10 : " $pm10
	echo "niveau : " $niveau
	echo "json : " $json
	echo "fichier json : "  $jsonfile
	echo "fichier xml : " $xmlfile
	echo "fichier txt : " $txtfile
	debugdate=$(date +%Y%m%d-%H:%M:%S)
	echo "$debugdate Fin Informations debug"
	echo "-----------------------------"
else
	debugdate=$(date +%Y-%m-%d--%H:%M:%S)
	echo "$debugdate $ville indice pollution: $indice -- o3 : $o3  -- no2 : $no2  --  PM10 : $pm10" 
fi

##########################################################################"
### Fin traitement
rm $tmpfile
