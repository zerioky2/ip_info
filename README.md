ip_info.sh — README

But du script
--------------
Collecte des informations basiques sur une adresse IP ou un nom d'hôte :
- whois (ASN / org / abuse)
- heuristiques VPN / datacenter
- détection Tor exit nodes
- géolocalisation via ip-api (si présent)
- sauvegarde du résultat dans /tmp/ip_info_<target>_<timestamp>.txt

Dépendances système
-------------------
Installer via apt (Debian/Ubuntu) :
sudo apt update && sudo apt install -y dnsutils whois curl jq iputils-ping traceroute nmap

Packages optionnels :
- traceroute : traceroute réseau
- nmap : scan de ports (commenté dans le script)
- ping6 / iputils-ping : pour tester IPv6

Fichier requirements.txt
------------------------

Emplacement et permissions
--------------------------
1. Placer le script :
   - Par défaut : /usr/local/bin/ ou ~/bin/ (si présent dans ton PATH)
   - Si tu veux qu'il soit disponible pour tous les utilisateurs : /usr/local/bin/ip_info.sh

2. Rendre exécutable :
   sudo chmod +x /usr/local/bin/ip_tracer_force_free.sh
   (ou chmod +x ./ip_info.sh si utilisé dans le répertoire courant)

3. Propriétaire (optionnel) :
   sudo chown root:root /usr/local/bin/ip_info.sh

Utilisation
-----------
Usage général :
./ip_info.sh <IP_or_hostname>

Exemples :
sudo /usr/local/bin/ip_info.sh 8.8.8.8
sudo /usr/local/bin/ip_info.sh example.com

Sortie
-----
- Le script enregistre un fichier de sortie dans /tmp nommé ip_info_<target>_<timestamp>.txt
- Les sorties importantes sont aussi affichées sur la console.

Sécurité et confidentialité
---------------------------
- Le script effectue des requêtes réseau (whois, dig, curl vers ip-api). Ne l'exécute pas sur des cibles dont tu n'as pas le droit d'interroger les informations.
- Conserver /tmp peut exposer les résultats à d'autres utilisateurs locaux ; supprimer manuellement le fichier si nécessaire :
  rm /tmp/ip_info_<target>_<timestamp>.txt

Personnalisation rapide
-----------------------
- Pour activer le scan de ports, décommenter la section nmap dans le script.
- Pour forcer IPv6, ajouter une option --ipv6 et adapter la résolution (le script actuel ne contient pas cette option).

Dépannage
---------
- Si "dig" introuvable : installe dnsutils.
- Si "jq" introuvable : installe jq pour parser JSON (utilisé pour ip-api).
- Si whois renvoie vide : vérifier connectivité réseau ou limiter la fréquence des requêtes.

Licence
-------
Par défaut : usage personnel.


