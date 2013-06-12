SPIP Scripts
============

Des scripts de maintenance pour SPIP

### SPIP Update

Script de base de mise à jour d'un SPIP sous svn

Ce script réalise plusieurs actions :

1. Vérifie qu'il y a des libs à mettre à jour dans lib/ en analysant les paquet.xml à mettre à jour des plugins
2. Met à jour SPIP
3. Met à jour les plugins
4. Met à jour les thèmes si dans themes/
5. Met à jour le répertoire mutualisation si présent

Pour l'utiliser facilement : 

1. Placez ce script dans le répertoire /usr/local/bin (permettant de l'appeler de partout sur le système)
2. Donnez lui les droits d'être exécuté :
	chmod +x /usr/local/bin/spip_update
3. Rendez vous à la racine d'un site SPIP et lancez la commande :
	spip_update
