docker stop testdb || true

docker run --rm --name testdb -p 5432:5432 -d postgres:10.6

# Wait for connection
for i in {1..10}; do (pg_isready -h localhost -U postgres && break) || sleep 1; done

psql -h localhost -U postgres -c "CREATE DATABASE graphql;"
psql -h localhost -U postgres -c "CREATE USER graphql WITH password 'password';"