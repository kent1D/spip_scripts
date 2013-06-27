#!/bin/bash
# spip_update
#
# © 2013 - kent1 (kent1@arscenic.info)
# Version 0.2.0
#

CURRENT=$(pwd)

# Les options de base
LOG=/dev/null
VERSION="0.2.0"
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

# Fonction d'installation des librairies
verifier_librairie()
{
	ZIP=$(echo $1 | sed 's/.*lien=\"\([^"]*\)\".*/\1/g')
	DIR=$(echo $1 | sed 's/.*nom=\"\([^"]*\)\".*/\1/g')
	FILE=$(echo $ZIP | sed 's/.*\///g' | sed 's/%20/ /g')

	# Si le répertoire de la lib n'existe pas
	# On va dans lib
	if [ ! -d "lib/$DIR" ];then
		cd lib/ 2>> $LOG >> $LOG

		# Si le zip n'est pas là on le récupère
		if [ ! -e "$FILE" ];then
			wget "$ZIP" 2>> $LOG >> $LOG
		fi

		# On check quel est le mime-type du fichier
		MIME=`file --mime-type "$FILE" |awk 'BEGIN { FS = ":" } ; {print $2}' | tr -d ' '`
		# Si c'est un zip, on sait le dézipper
		if [ $MIME = 'application/zip' ]; then
			FIRST=`zipinfo -1 "$FILE" | head -1`
			# Si le premier fichier listé dans le zip est le répetoire espéré
			# On dézip simplement le fichier zip récupéré
			if [ "$FIRST" = "$DIR"/ ];then
				unzip "$FILE" 2>> $LOG >> $LOG
			# Si le premier fichier listé dans le zip est un répertoire mais pas celui espéré
			# On dézip le fichier zip récupéré
			# On renomme le répertoire
			elif [ "${FIRST:-1}" = "/" ];then 
				unzip "$FILE" 2>> $LOG >> $LOG
				mv "$FIRST" "$DIR" 2>> $LOG >> $LOG
			# Sinon c'est que ce ne sont que des fichiers à la racine du zip
			# On dézip donc le fichier dans le répertoire espéré
			else
				unzip "$FILE" -d "$DIR" 2>> $LOG >> $LOG
			fi
			rm "$FILE" 2>> $LOG >> $LOG
		else
			echo "Erreur de récupération du fichier $FILE"
		fi

		if [ ! -d "$DIR" ]; then
			echo "Erreur de création du répertoire $DIR"
		fi
		cd ..
	fi
}

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

# Mise à jour de SPIP et on met les droits corrects
echo
echo "Mise à jour de SPIP"
svn up 2>> $LOG >> $LOG
chown -Rvf $USER:$GROUP prive/ squelettes-dist/ ecrire/ local/ 2>> $LOG >> $LOG
echo

# Mise à jour des plugins et on met les droits corrects
echo "Mise à jour des répertoires de plugins"
svn up plugins*/* 2>> $LOG >> $LOG
chown -Rvf $USER:$GROUP plugins*/ 2>> $LOG >> $LOG
echo

echo "Vérification des librairies"
echo

# On check chaque librairie
IFS="
"
for line in ` grep -hr "<lib " plugins*/*/p*.xml 2> /dev/null`;do
	verifier_librairie $line
done
chown -Rvf $USER:$GROUP lib/ 2>> $LOG >> $LOG

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