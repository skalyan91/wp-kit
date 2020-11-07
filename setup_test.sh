while [ -z "$name" ]; do
  read -p  "     Site name: " name
done

wp_container_exists="$(docker ps -a | grep "\b${name}_wordpress")"
db_container_exists="$(docker ps -a | grep "\b${name}_db")"
echo $wp_container_exists
echo $db_container_exists
