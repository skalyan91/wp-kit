#!/usr/bin/env bash
set -eo pipefail

if [[ $EUID -ne 0 ]]; then
   printf "\033[1;31mERROR:\033[0m This script must be run as root\n" 
   exit 1
fi

while [ -z "$name" ]; do
  read -p  "     Site name: " name
done
while [ -z "$db" ]; do
  read -p  " Database name: " db
done
while [ -z "$username" ]; do
  read -p  "MySQL username: " username
done
while [ -z "$password" ]; do
  read -sp "MySQL password: " password; echo ""
  read -sp "Re-enter MySQL password: " rpassword; echo ""
  if [[ $password != $rpassword ]]; then
    password=""
    echo "Passwords do not match. Please try again."
  fi
done

echo "Checking if any prerequisites need to be installed or upgraded..."
apt-get update > /dev/null
apt-get -q install unzip php libapache2-mod-php mysql-server php-mysql

prefix="/var/www/$name"
[ -d "$prefix" ] &&
  { printf "\033[1;31mERROR:\033[0m Directory $prefix already exists. Please move/delete and try again.\n";
    exit 1; }
echo "Downloading WordPress..."
wget -q --show-progress -P "$prefix/" https://en-gb.wordpress.org/latest-en_GB.zip
echo "Extracting to $prefix/..."
unzip "$prefix/latest-en_GB.zip" -d "$prefix/" > /dev/null
mv "$prefix/wordpress/"* "$prefix/"
rm -rf "$prefix/wordpress/"
rm "$prefix/latest-en_GB.zip"
chown -R www-data "$prefix/"

echo "Creating configuration files..."
cat wordpress.conf |
  sed "s/blog/$name/g" > "/etc/apache2/sites-available/$name-wordpress.conf"
cat wordpress.bat |
  sed "s/db/$db/g" |
  sed "s/username/$username/g" |
  sed "s/password/$password/g" | mysql
cat "$prefix/wp-config-sample.php" |
  sed "s/database_name_here/$db/g" |
  sed "s/username_here/$username/g" |
  sed "s/password_here/$password/g" > "$prefix/wp-config.php"
echo "define('FS_METHOD', 'direct');
define('DISALLOW_FILE_EDIT', true);" >> "$prefix/wp-config.php"
echo "Disabling PHP execution in uploads folder..."
mkdir -p "$prefix/wp-content/uploads/"
cp .htaccess "$prefix/wp-content/uploads/"

echo "Launching your website..."
service mysql start
a2ensite "$name-wordpress" > /dev/null
systemctl reload apache2

echo "All done! Enjoy!"
