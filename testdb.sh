#/bin/bash
set -e

# Defaults
stop=false
start=false
connect=false

# Parse Options
OPTIONS=hr
LONGOPTIONS=help,reset,restart,stop,start,connect

USAGE="
USAGE: ./startdb.sh [OPTIONS]

Options:
 -h  --help       Display this message.
 -r  --reset      Reset the database.
     --restart    Alies: --reset
     --stop       Stop the database.
     --start      Start the database if not already started.
 -c  --connect    Connect to the database.
 
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
		-r|--reset|--restart)
			stop=true
			start=true
			shift 1
			;;
		--start)
			start=true
			shift 1
			;;
		--stop)
			stop=true
			shift 1
			;;
		-c|--connect)
			connect=true
			shift 1
			;;
		--)
			shift
			break
			;;
	esac
done

is_running () {
	docker run --rm --network "host" --entrypoint sh jbergknoff/postgresql-client -c "pg_isready -h localhost -p 5432 &> /dev/null"
}

stop_db () {
	docker stop testdb || true
}

start_db () {
	docker run --rm --name testdb -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:10.6

	./initdb.sh --host localhost --port 5432 --username postgres --password password --new-username graphql --new-password password
}

connect_db () {
	docker run --rm -it --network "host" -v $current_directory/init-db.sql:/init-db.sql jbergknoff/postgresql-client postgresql://graphql:password@localhost:5432
}


if [ $stop = true ]; then
	if is_running ; then
		stop_db
	else
		echo "Database already stopped."
	fi
fi

if [ $start = true ]; then
	if is_running ; then
		echo "Database already running at localhost:5432"
	else
		start_db
	fi
fi

if [ $connect = true ]; then
	if is_running ; then
		connect_db
	else
		echo "Database is not running, use './testdb.sh --start' to start it."
	fi
fi

if [ $stop = false ] && [ $start = false ] && [ $connect = false ]; then
	if is_running ; then
		echo "Database running at localhost:5432"
	else
		echo "Database stopped."
	fi
fi 