#!/usr/bin/env bash
set -eo pipefail

rederror="\033[1;31mERROR:\033[0m"

if [ $EUID -ne 0 ]; then
   printf "$rederror This script must be run as root\n" 
   exit 1
fi

while [ -z "$name" ]; do
  read -p  "     Site name: " name
done

prefix="/var/www/$name"
if [ ! -d "$prefix" ]; then
  read -p "Directory $prefix does not exist. Do you want me to create it? (y/N) " create
  if [ "${create,,}" != "y" ]; then
    echo "Please create $prefix and then run this script again."
    exit 1
  else
    mkdir -p "$prefix/db_data"
  fi
fi

containers_running=[ \( -n $(docker ps -a | grep "^${name}_wordpress") \) -a \
     \( -n $(docker ps -a | grep "^${name}_db") \) ]

if $containers_running; then
  printf "$rederror There are already Docker containers running for the $name site.\n"
  exit 1
fi

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
while [ -z "$rootpassword" ]; do
  read -sp "MySQL root password: " rootpassword; echo ""
  read -sp "Re-enter MySQL root password: " rrootpassword; echo ""
  if [[ $rootpassword != $rrootpassword ]]; then
    rootpassword=""
    echo "Passwords do not match. Please try again."
  fi
done

echo "Uninstalling old versions of Docker..."
apt-get remove docker docker.io containerd runc

echo "Installing any necessary dependencies..."
apt-get update > /dev/null
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    pwgen
if [ -z "$(cat /etc/apt/sources.list | grep "download\.docker\.com")" ]; then
  echo "Setting up official Docker repository..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  if [ -z "$(apt-key fingerprint 0EBFCD88 | grep "0EBF CD88$")" ]; then
    echo "$rederror Fingerprint does not match!"
    exit 1
  fi
  add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
fi

echo "Installing Docker (if necessary)..."
apt-get update > /dev/null
apt-get install docker-ce docker-ce-cli containerd.io

echo "Installing docker-compose..."
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Generating docker-compose file..."
cat docker-compose-template.yml |
  sed "s/db_name/$db/g" |
  sed "s/mysql_username/$username/g" |
  sed "s/mysql_password/$password/g" |
  sed "s/root_password/$rootpassword/g" > "$prefix/docker-compose.yml"

echo "Starting up Docker containers..."
(
  cd "$prefix"
  containers="$(docker ps --filter name="${name}_*" -aq)"
  if [ -n "$containers" ]
  then
    echo $containers | xargs docker stop | xargs docker rm
  else
    echo "No containers need to be removed."
  fi
  docker-compose up -d
  while [ "${continue,,}" != "y" ]; do
    read -p  "On the next screen, you need to enter a secure passphrase. Continue? (y/N) " continue
  done
  gpg --no-symkey-cache -c docker-compose.yml
  rm docker-compose.yml
)

read -p "Would you like to use the local IP address? (y/N) " local_ip
if [ "${local_ip,,}" == "y" ]; then
  ip=$(hostname -I | awk '{print $1}')
else
  ip=$(curl ifconfig.me)
fi

echo "Your Docker containers are now up and running! Go to http://$ip:8000 to start setting up WordPress."
