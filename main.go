package main

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

const (
	dbHost     = "localhost"
	dbPort     = "5432"
	dbUser     = "graphql"
	dbPassword = "password"
	dbName     = "graphql"
)

var schema = `
CREATE TABLE IF NOT EXISTS authors (
	id serial PRIMARY KEY,
	name varchar(100) NOT NULL,
	email varchar(150) NOT NULL,
	created_at date
);

CREATE TABLE IF NOT EXISTS post (
	id serial PRIMARY KEY,
	title varchar(100) NOT NULL,
	content text NOT NULL,
	author_id int,
	created_at date
);`

// Author ...
type Author struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

// Post ...
type Post struct {
	ID        int       `json:"id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	AuthorID  int       `json:"author_id"`
	CreatedAt time.Time `json:"created_at"`
}

func checkErr(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	dbinfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", dbHost, dbPort, dbUser, dbPassword, dbName)

	db, err := sql.Open("postgres", dbinfo)
	checkErr(err)
	defer db.Close()

	fmt.Println(dbinfo)
}
