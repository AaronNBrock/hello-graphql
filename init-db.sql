CREATE TABLE IF NOT EXISTS authors (
    id serial PRIMARY KEY,
    name varchar(100) NOT NULL,
    email varchar(150) NOT NULL,
    created_at date NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS posts (
    id serial PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(id),
    created_at DATE NOT NULL DEFAULT CURRENT_DATE
);