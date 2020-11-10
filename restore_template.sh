#!/usr/bin/env bash
set -euo pipefail

rederror="\033[1;31mERROR:\033[0m"

if [ $EUID -ne 0 ]; then
   printf "$rederror This script must be run as root\n" 
   exit 1
fi

cd /var/www/backups

echo "Installing any necessary dependencies..."
apt-get update > /dev/null
apt-get -q install unzip php libapache2-mod-php mysql-server php-mysql

echo "Unzipping document root backup..."
unzip -: folder_backup.zip

echo "Restoring MySQL database..."
mysql < mysql_backup.sql

db_user=$(cat "../rsite/wp-config.php" | grep DB_USER | cut -d\' -f4)
db_password=$(cat "../rsite/wp-config.php" | grep DB_PASSWORD | cut -d\' -f4)

sql_command="grant all privileges on rdb.* to $db_user@localhost identified by '$db_password';
flush privileges;"

mysql -e "$sql_command"

echo "Congratulations! The rsite site and rdb database have been restored successfully."
