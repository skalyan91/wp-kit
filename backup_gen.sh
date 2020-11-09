#!/usr/bin/env bash
set -euo pipefail

rederror="\033[1;31mERROR:\033[0m"

if [ $EUID -ne 0 ]; then
    printf "$rederror This script must be run as root\n" 
    exit 1
fi

name=""
db=""

while [ -z $name ]; do
    read -p  "    Site name: " name
    if [ ! -d "/var/www/$name" ]; then
        printf "$rederror The directory /var/www/$name/ does not exist! Please try again.\n"
        name=""
    fi
done
while [ -z "$db" ]; do
    read -p  "Database name: " db
    if [ -n "$db" ]; then
        if [ -z "$(mysql -e "show databases like '$db'")" ]; then
            printf "$rederror The database '$db' does not exist! Please try again.\n"
            db=""
        fi
    fi
done

mkdir -p /var/www/scripts/

if [ -f "/var/www/scripts/backup_$name.sh" ]; then
    read -p \
        "The script /var/www/scripts/backup_$name.sh already exists. Do you wish to overwrite it? (y/N) " \
        overwrite
    if [ "${overwrite,,}" != "y" ]; then
        exit 1
    fi
fi

cat backup_template.sh |
    sed "s/site_name/$name/g" |
    sed "s/db_name/$db/g" > "/var/www/scripts/backup_$name.sh"
chmod +x "/var/www/scripts/backup_$name.sh"

echo "The backup script has been created at /var/www/scripts/backup_$name.sh"

cat restore_template.sh |
    sed "s/folder_backup/$(date '+%Y-%m-%d_%H-%M-%S')_$name/g" |
    sed "s/mysql_backup/$(date '+%Y-%m-%d_%H-%M-%S')_$db/g" |
    sed "s/site_name/$name/g" |
    sed "s/db_name/$db/g" > "/var/www/scripts/restore_$name.sh"
chmod +x "/var/www/scripts/restore_$name.sh"

echo "The restore script has been created at /var/www/scripts/restore_$name.sh"
