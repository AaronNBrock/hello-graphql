docker run --rm -it --network "host" -v $current_directory/init-db.sql:/init-db.sql jbergknoff/postgresql-client postgresql://graphql:password@localhost:5432