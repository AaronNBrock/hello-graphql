#/bin/bash

# Defaults
host="localhost"
port="5432"
username="postgres"
password="password"
new_username="graphql"
new_password="password"

# Parse Options
OPTIONS=hH:p:u:p:
LONGOPTIONS=help,host:,port:,username:,password:,new-username:,new-password:

USAGE="
USAGE: ./initdb.sh [OPTIONS]

Options:
 -h  --help            Display this message.
 -H, --host            The postgres host ip. (default '$host')
 -p, --port            The port to connect to. (default '$port')
 -u, --username        The username to connect with. (default '$username')
 -P, --password        The password to connect with. (default '$password')
     --new-username    The new username. (default '$new_username')
     --new-password    The new password. (default '$new_password')
"

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

[ $? != 0 ] && echo "$0: Could not parse arguments" && echo "$USAGE" && exit 1

eval set -- $PARSED

while true; do
	case "$1" in
		-h|--help)
			echo "$USAGE"
			exit
			;;
		-H|--host)
			host=$2
			shift 2
			;;
		-p|--port)
			port=$2
			shift 2
			;;
		-u|--username)
			username=$2
			shift 2
			;;
		-P|--password)
			password=$2
			shift 2
			;;
		--new-username)
			new_username=$2
			shift 2
			;;
		--new-password)
			new_password=$2
			shift 2
			;;
		--)
			shift
			break
			;;
	esac
done


# Wait for connection
docker run --rm --network "host" --entrypoint sh jbergknoff/postgresql-client -c "while ! pg_isready -h $host -p $port; do sleep 2; done"

# Create User
docker run --rm --network "host" jbergknoff/postgresql-client postgresql://$username:$password@$host:$port -c "CREATE USER $new_username WITH password '$new_password';"

# Create Database
docker run --rm --network "host" jbergknoff/postgresql-client postgresql://$username:$password@$host:$port -c "CREATE DATABASE $new_username;"

# Docker for Windows support
current_directory=$(pwd -W 2> /dev/null || pwd)

# Init table database scheme.
docker run --rm --network "host" -v $current_directory/init-db.sql:/init-db.sql jbergknoff/postgresql-client postgresql://$new_username:$new_password@$host:$port -f init-db.sql
