#/bin/bash

OPTIONS=hH:p:u:p:
LONGOPTS=help,hostname:,port:,username:,password:

USAGE="
USAGE: ./initdb.sh [OPTIONS]

Options:
 -h  --help            Display this message.
 -H, --host            The postgres host ip. (default 'localhost')
 -p, --port            The port to connect to. (default '5432')
 -u, --username        The username to connect with. (default 'postgres')
 -P, --password        The password to connect with. (default 'password')
     --new-username    The new username. (default 'graphql')
     --new-password    The new password. (default 'password')
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

if [ -z ${host+x} ]; then
	host="localhost"
fi

if [ -z ${port+x} ]; then
	port="5432"
fi

if [ -z ${username+x} ]; then
	username="postgres"
fi

if [ -z ${password+x} ]; then
	password="password"
fi

if [ -z ${new_username+x} ]; then
	new_username="graphql"
fi

if [ -z ${new_password+x} ]; then
	new_password="password"
fi


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
