#!/usr/bin/env bash
set -euo pipefail

rederror="\033[1;31mERROR:\033[0m"

if [ $EUID -ne 0 ]; then
   printf "$rederror This script must be run as root\n" 
   exit 1
fi

mkdir -p /var/www/backups/
cd /var/www/backups/
mysqldump --databases db_name > $(date '+%Y-%m-%d')_db_name.sql
zip -r $(date '+%Y-%m-%d')_site_name ../site_name
