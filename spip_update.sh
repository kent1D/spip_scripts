#!/bin/bash
# spip_update
#
# © 2013 - kent1 (kent1@arscenic.info)
# Version 0.1.0
#

CURRENT=$(pwd)

# Les options de base
LOG=/dev/null
VERSION="0.1.0"
USER=""
GROUP=""
VIDER_CACHE=false

# On insère un fichier de modification de ces variables si présent
if [ -r /etc/default/spip_update ]; then
	. /etc/default/spip_update
fi

# Prendre en compte les options passées en paramètre du script
while [ $# -gt 0 ]; do
	case $1 in
		--version|-v) echo "SPIP Update"
		echo "Version : $VERSION"  
		exit 0;;
		--log|-l) LOG="${2}"
		shift 2;;
		--empty-cache|-e) VIDER_CACHE="oui"
		shift;;
		--user|-u) USER="${2}"
		shift 2;;
		--group|-g) GROUP="${2}"
		shift 2;;
	esac
done

echo "SPIP Update $VERSION"

# Pas de répertoire .svn à la racine ou pas de spip.php
# => Pas SPIP versionnalisé, on sort
if [ ! -d .svn ] || [ ! -e ./spip.php ]; then
	echo
	echo "Vous n êtes pas dans un répertoire SPIP sous svn"
	echo
	exit 1
fi

# USER vide, on utilise celui de spip.php
if [ "$USER" = "" ]; then
	USER=$(ls -l spip.php | awk '{ print $3 }')
fi
# GROUP vide, on utilise celui de spip.php
if [ "$GROUP" = "" ]; then
	GROUP=$(ls -l spip.php | awk '{ print $4 }')
fi

echo
echo "Vérification des librairies"
echo

IFS="
"

# On test chaque paquet.xml des répertoires plugins*
# Si un contient un changement de lib :
# On télécharge la lib
# On dézip la lib
# On vérifie bien tout
for line in `svn diff -r HEAD plugins*/*/paquet.xml 2> /dev/null |grep '<lib' |grep '^-'`;do
	
	ZIP=$(echo $line | sed 's/.*lien=\"\([^"]*\)\".*/\1/g')
	DIR=$(echo $line | sed 's/.*nom=\"\([^"]*\)\".*/\1/g')
	file=$(echo $ZIP | sed 's/.*\///g')
	
	if [ ! -d lib ];then
		echo "Création du répertoire lib inexistant"
		mkdir lib && chmod 755 lib/
		echo
	fi
	
	if [ ! -d lib/$DIR ];then
		echo "Récupération de $FILE ($ZIP) dans le répertoire $DIR"
		cd lib/
		
		if [ ! -e $FILE ];then
			wget $ZIP 2>> $LOG >> $LOG
		else
			echo "Le fichier existait déjà"
		fi

		MIME=`file --mime-type "$file" |awk 'BEGIN { FS = ":" } ; {print $2}' {print $2}' | tr -d ' '`
		if [ $MIME == 'application/zip' ]; then
			echo "Extraction de $file ($MIME)"
			first=`zipinfo -1 "$file" | head -1`
			if [ "$first" = "$DIR"/ ];then
				unzip "$file" 2>> $LOG >> $LOG		
			elif [ "${first:-1}" = "/" ];then 
				unzip "$file" 2>> $LOG >> $LOG
				mv "$first" "$DIR"
			else
				unzip "$file" -d "$DIR" 2>> $LOG >> $LOG
			fi
			rm "$file"
		else
			echo "Le fichier $FILE n'a pu être extrait"
		fi

		if [ ! -d $DIR ]; then
			echo "Erreur dans la création du répertoire $DIR"
			exit 1
		fi
		cd ..
	fi
	chown -Rvf $USER:$GROUP lib/ 2>> $LOG >> $LOG
	echo
done

# Mise à jour de SPIP et on met les droits corrects
echo "Mise à jour de SPIP"
svn up 2>> $LOG >> $LOG
chown -Rvf $USER:$GROUP prive/ squelettes-dist/ ecrire/ local/ 2>> $LOG >> $LOG
echo

# Mise à jour des plugins et on met les droits corrects
echo "Mise à jour des répertoires de plugins"
svn up plugins*/* 2>> $LOG >> $LOG
chown -Rvf $USER:$GROUP plugins*/ 2>> $LOG >> $LOG
echo

# Si un répertoire themes existe : mise à jour des themes et on met les droits corrects
if [ -d themes ]; then
	echo "Mise à jour des thèmes"
	svn up themes/* 2>> $LOG >> $LOG
	chown -Rvf $USER:$GROUP themes/ 2>> $LOG >> $LOG
	echo
fi

# Si un répertoire mutualisation existe : mise à jour de mutualisation et on met les droits corrects
if [ -d mutualisation ]; then
	echo "Mise à jour du répertoire de mutualisation"
	svn up mutualisation/ 2>> $LOG >> $LOG
	chown -Rvf $USER:$GROUP mutualisation/ 2>> $LOG >> $LOG
	echo
fi

exit 0