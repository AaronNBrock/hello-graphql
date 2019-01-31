#/bin/bash
set -e

# Defaults
stop=false
start=false

# Parse Options
OPTIONS=hr
LONGOPTIONS=help,reset,restart,stop,start

USAGE="
USAGE: ./startdb.sh [OPTIONS]

Options:
 -h  --help       Display this message.
 -r, --reset      Reset the database.
     --restart    Alies: --reset
     --stop       Stop the database.
     --start      Start the database.
 
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
		--)
			shift
			break
			;;
	esac
done

if [ $stop = true ]; then
	docker stop testdb || true
else if docker run --rm --network "host" --entrypoint sh jbergknoff/postgresql-client -c "pg_isready -h localhost -p 5432 &> /dev/null" ; then
	echo "Database already running."
	exit 0
fi
fi

if [ $start = true ]; then
	docker run --rm --name testdb -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:10.6

	./initdb.sh --host localhost --port 5432 --username postgres --password password --new-username graphql --new-password password
else
	echo "Database not running."
	exit 0
fi
