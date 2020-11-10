#!/usr/bin/env bash
set -euo pipefail

# Backs up the db_name database and the site_name site into /var/www/backups/

rederror="\033[1;31mERROR:\033[0m"

if [ $EUID -ne 0 ]; then
   printf "$rederror This script must be run as root\n" 
   exit 1
fi

time_stamp=$(date '+%Y-%m-%d_%H-%M-%S')

echo "Backing up the site_name site and database..."
mkdir -p /var/www/backups/
cd /var/www/backups/
mysqldump --databases db_name > ${time_stamp}_db_name.sql
zip -r ${time_stamp}_site_name ../site_name > ${time_stamp}_site_name_backup.log

echo "Creating a script to restore the backed-up site and database..."
cat /var/www/scripts/restore_template.sh |
    sed "s/folder_backup/${time_stamp}_site_name/g" |
    sed "s/mysql_backup/${time_stamp}_db_name/g" |
    sed "s/rsite/site_name/g" |
    sed "s/rdb/db_name/g" > "/var/www/scripts/${time_stamp}_restore_site_name.sh"
chmod +x "/var/www/scripts/${time_stamp}_restore_site_name.sh"

echo "The restore script has been created at /var/www/scripts/${time_stamp}_restore_site_name.sh"

