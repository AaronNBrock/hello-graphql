docker stop testdb || true

docker run --rm --name testdb -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:10.6

./initdb.sh --host localhost --port 5432 --username postgres --password password --new-username graphql --new-password password