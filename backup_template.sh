#!/usr/bin/env bash
set -euo pipefail

# Backs up the db_name database and the site_name site into /var/www/backups/

rederror="\033[1;31mERROR:\033[0m"

if [ $EUID -ne 0 ]; then
   printf "$rederror This script must be run as root\n" 
   exit 1
fi

mkdir -p /var/www/backups/
cd /var/www/backups/
mysqldump --databases db_name > $(date '+%Y-%m-%d_%H:%M:%S')_db_name.sql
zip -r $(date '+%Y-%m-%d_%H:%M:%S')_site_name ../site_name > $(date '+%Y-%m-%d_%H:%M:%S')_site_name_backup.log
