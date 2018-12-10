docker stop testdb || true

docker run --rm --name testdb -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:10.6

# Wait for connection
docker run --rm --network "host" --entrypoint /bin/sh jbergknoff/postgresql-client -c "while ! pg_isready -h localhost; do sleep 2; done"

# Create User
docker run --rm --network "host" jbergknoff/postgresql-client postgresql://postgres:password@localhost:5432 -c "CREATE USER graphql WITH password 'password';"

# Create Database
docker run --rm --network "host" jbergknoff/postgresql-client postgresql://postgres:password@localhost:5432 -c "CREATE DATABASE graphql;"

# Docker for Windows support
current_directory=$(pwd -W 2> /dev/null || pwd)

# Init table database scheme.
docker run --rm --network "host" -v $current_directory/init-db.sql:/init-db.sql jbergknoff/postgresql-client postgresql://graphql:password@localhost:5432 -f init-db.sql