#!/usr/bin/env bash
set -euo pipefail

name="blog"
db="wordpress"
username="wordpress"
password="wordpress"

while getopts ":n:d:u:p:h:" opt; do
  case $opt in
    n) name="$OPTARG"
       db="wordpress_$name"
       ;;
    d) db="$OPTARG"
       ;;
    u) username="$OPTARG"
       ;;
    p) password="$OPTARG"
       ;;
    h) cat setup_help.txt
  esac
done

echo "Checking if any prerequisites need to be installed or upgraded..."
sudo apt-get update > /dev/null
sudo apt-get -q install php libapache2-mod-php mysql-server php-mysql

prefix="/var/www/$name"
[ -d "$prefix" ] &&
  { printf "\033[1;31mERROR:\033[0m Directory $prefix already exists. Please move/delete and try again.\n";
    exit 1; }
echo "Downloading WordPress..."
sudo wget -q --show-progress -P "$prefix/" https://en-gb.wordpress.org/latest-en_GB.zip
echo "Extracting to $prefix/..."
sudo unzip "$prefix/latest-en_GB.zip" -d "$prefix/" > /dev/null
sudo mv "$prefix/wordpress/"* "$prefix/"
sudo rm -rf "$prefix/wordpress/"
sudo rm "$prefix/latest-en_GB.zip"
sudo chown -R www-data "$prefix/"

echo "Creating configuration files..."
cat wordpress.conf |
  sed "s/blog/$name/g" |
  sudo tee "/etc/apache2/sites-available/$name-wordpress.conf" > /dev/null
cat wordpress.bat |
  sed "s/db/$db/g" |
  sed "s/username/$username/g" |
  sed "s/password/$password/g" |
  sudo mysql
cat "$prefix/wp-config-sample.php" |
  sed "s/database_name_here/$db/g" |
  sed "s/username_here/$username/g" |
  sed "s/password_here/$password/g" |
  sudo tee "$prefix/wp-config.php" > /dev/null
echo "define('FS_METHOD', 'direct');
define('DISALLOW_FILE_EDIT', true);" |
  sudo tee -a "$prefix/wp-config.php" > /dev/null
echo "Disabling PHP execution in uploads folder..."
sudo mkdir -p "$prefix/wp-content/uploads/"
sudo cp .htaccess "$prefix/wp-content/uploads/"

echo "Launching your website..."
sudo service mysql start
sudo a2ensite "$name-wordpress" > /dev/null
sudo systemctl reload apache2

echo "All done! Enjoy!"
