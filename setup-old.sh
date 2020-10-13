#!/usr/bin/env bash
set -euo pipefail

name="blog"
db="wordpress"
username="wordpress"
password="wordpress"
ipaddr=$(hostname -I | awk '{print $1}')
            
while getopts ":n:d:u:p:" opt; do
    case $opt in
        n) name="$OPTARG"
           ;;
        d) db="$OPTARG"
           ;;
        u) username="$OPTARG"
           ;;
        p) password="$OPTARG"
           ;;
    esac
done

sudo apt update
sudo apt install wordpress php libapache2-mod-php mysql-server php-mysql

cat wordpress.conf |
    sed "s/blog/$name/g" |
    sudo tee /etc/apache2/sites-available/wordpress.conf
cat wordpress.bat |
      sed "s/db/$db/g" |
      sed "s/username/$username/g" |
      sed "s/password/$password/g" |
      sudo mysql
sudo rm -f /etc/wordpress/*.php
cat config-localhost.php |
    sed "s/db/$db/g" |
    sed "s/username/$username/g" |
    sed "s/password/$password/g" |
    sudo tee "/etc/wordpress/config-$ipaddr.php"
# sudo mkdir -p /usr/share/wordpress/wp-includes/
# sudo cp .htaccess /usr/share/wordpress/wp-includes/
# sudo mkdir -p /usr/share/wordpress/wp-content/uploads/
# sudo cp .htaccess /usr/share/wordpress/wp-content/uploads/
sudo service mysql start
sudo a2ensite wordpress
sudo systemctl reload apache2

# sudo chmod 755 -R /usr/share/wordpress/wp-admin \
#   /usr/share/wordpress/wp-content /usr/share/wordpress/wp-includes
# # sudo chmod 644 /usr/share/wordpress/*
# sudo chown -R www-data /usr/share/wordpress
