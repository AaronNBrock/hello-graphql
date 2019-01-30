package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/graphql-go/graphql"
	"github.com/graphql-go/handler"
	_ "github.com/lib/pq"
)

// Author ...
type Author struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"createdAt"`
}

// Post ...
type Post struct {
	ID        int       `json:"id"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	AuthorID  int       `json:"authorID"`
	CreatedAt time.Time `json:"createdAt"`
}

var graphqlHandler http.Handler

var (
	dbHost  string
	dbPort  string
	dbUser  string
	dbPass  string
	dbName  string
	appPort string
)

func checkErr(err error) {
	if err != nil {
		panic(err)
	}
}

// Database functions

// Author
func createAuthor(db *sql.DB, name string, email string) (*Author, error) {
	author := &Author{
		Name:  name,
		Email: email,
	}

	err := db.QueryRow("INSERT INTO authors (name, email) VALUES ($1, $2) RETURNING id, created_at;", name, email).Scan(&author.ID, &author.CreatedAt)
	if err != nil {
		return nil, err
	}

	return author, nil
}

func deleteAuthor(db *sql.DB, authorID int) (bool, error) {
	stmt, err := db.Prepare("DELETE FROM authors WHERE id = $1;")
	if err != nil {
		return false, err
	}

	result, err := stmt.Exec(authorID)
	if err != nil {
		return false, err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return false, err
	}

	return rowsAffected > 0, nil
}

func queryAuthor(db *sql.DB, authorID int) (*Author, error) {
	author := &Author{}

	err := db.QueryRow("SELECT id, name, email, created_at FROM authors WHERE id = $1;", authorID).Scan(&author.ID, &author.Name, &author.Email, &author.CreatedAt)
	if err != nil {
		return nil, err
	}

	return author, nil
}

func queryAuthors(db *sql.DB) ([]*Author, error) {
	fmt.Println("Executing query")
	rows, err := db.Query("SELECT id, name, email, created_at FROM authors;")

	if err != nil {
		return nil, err
	}
	var authors []*Author

	fmt.Println("Starting scan")
	for rows.Next() {
		author := &Author{}
		err = rows.Scan(&author.ID, &author.Name, &author.Email, &author.CreatedAt)
		if err != nil {
			return nil, err
		}
		authors = append(authors, author)
	}
	fmt.Println("Returning authors")
	return authors, err
}

// Post
func createPost(db *sql.DB, title string, content string, authorID int) (*Post, error) {
	post := &Post{
		Title:    title,
		Content:  content,
		AuthorID: authorID,
	}

	err := db.QueryRow("INSERT INTO posts (title, content, author_id) VALUES ($1, $2, $3) RETURNING id, created_at;", title, content, authorID).Scan(&post.ID, &post.CreatedAt)
	if err != nil {
		return nil, err
	}

	return post, nil
}

func deletePost(db *sql.DB, postID int) (bool, error) {
	stmt, err := db.Prepare("DELETE FROM posts WHERE id = $1;")
	if err != nil {
		return false, err
	}

	result, err := stmt.Exec(postID)
	if err != nil {
		return false, err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return false, err
	}

	return rowsAffected > 0, nil
}

func queryPost(db *sql.DB, postID int) (*Post, error) {
	post := &Post{}

	err := db.QueryRow("SELECT id, title, content, author_id, created_at FROM posts WHERE id = $1;", postID).Scan(&post.ID, &post.Title, &post.Content, &post.AuthorID, &post.CreatedAt)
	if err != nil {
		return nil, err
	}

	return post, nil
}

func queryPosts(db *sql.DB) ([]*Post, error) {
	rows, err := db.Query("SELECT id, title, content, author_id, created_at FROM posts;")

	if err != nil {
		return nil, err
	}
	var posts []*Post

	for rows.Next() {
		post := &Post{}
		err = rows.Scan(&post.ID, &post.Title, &post.Content, &post.AuthorID, &post.CreatedAt)
		if err != nil {
			return nil, err
		}
		posts = append(posts, post)
	}
	return posts, err
}

func init() {
	// Define defaults
	dbHost  = "localhost"
	dbPort  = "5432"
	dbUser  = "graphql"
	dbPass  = "password"
	dbName  = "graphql"

	appPort = "8080"


	if env := os.Getenv("DB_HOST"); env != "" {
		dbHost = env
	}
	if env := os.Getenv("DB_PORT"); env != "" {
		dbPort = env
	}
	if env := os.Getenv("DB_USER"); env != "" {
		dbUser = env
	}
	if env := os.Getenv("DB_PASS"); env != "" {
		dbPass = env
	}
	if env := os.Getenv("DB_NAME"); env != "" {
		dbName = env
	}

	if env := os.Getenv("APP_PORT"); env != "" {
		appPort = env
	}

	dbinfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", dbHost, dbPort, dbUser, dbPass, dbName)

	db, err := sql.Open("postgres", dbinfo)
	checkErr(err)
	// defer db.Close()

	authorType := graphql.NewObject(graphql.ObjectConfig{
		Name:        "Author",
		Description: "An author",
		Fields: graphql.Fields{
			"id": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.Int),
				Description: "The identifier of the author.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if author, ok := p.Source.(*Author); ok {
						return author.ID, nil
					}

					return nil, nil
				},
			},
			"name": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.String),
				Description: "The name of the author.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if author, ok := p.Source.(*Author); ok {
						return author.Name, nil
					}

					return nil, nil
				},
			},
			"email": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.String),
				Description: "The email address of the author.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if author, ok := p.Source.(*Author); ok {
						return author.Email, nil
					}

					return nil, nil
				},
			},
			"createdAt": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.String),
				Description: "The createdAt date of the author.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if author, ok := p.Source.(*Author); ok {
						return author.CreatedAt, nil
					}

					return nil, nil
				},
			},
		},
	})

	postType := graphql.NewObject(graphql.ObjectConfig{
		Name:        "Post",
		Description: "A Post",
		Fields: graphql.Fields{
			"id": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.Int),
				Description: "The identifier of the post.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if post, ok := p.Source.(*Post); ok {
						return post.ID, nil
					}

					return nil, nil
				},
			},
			"title": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.String),
				Description: "The title of the post.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if post, ok := p.Source.(*Post); ok {
						return post.Title, nil
					}

					return nil, nil
				},
			},
			"content": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.String),
				Description: "The content of the post.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if post, ok := p.Source.(*Post); ok {
						return post.Content, nil
					}

					return nil, nil
				},
			},
			"createdAt": &graphql.Field{
				Type:        graphql.NewNonNull(graphql.String),
				Description: "The createdAt date of the post.",
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if post, ok := p.Source.(*Post); ok {
						return post.CreatedAt, nil
					}

					return nil, nil
				},
			},
			"author": &graphql.Field{
				Type: authorType,
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					if post, ok := p.Source.(*Post); ok {
						author, err := queryAuthor(db, post.AuthorID)
						checkErr(err)

						return author, nil
					}

					return nil, nil
				},
			},
		},
	})

	rootQuery := graphql.NewObject(graphql.ObjectConfig{
		Name: "RootQuery",
		Fields: graphql.Fields{
			// Authors
			"author": &graphql.Field{
				Type:        authorType,
				Description: "Get an author.",
				Args: graphql.FieldConfigArgument{
					"id": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.Int),
					},
				},
				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					// ToDo deal with ok
					postID, _ := params.Args["id"].(int)

					author, err := queryAuthor(db, postID)
					checkErr(err)

					return author, nil
				},
			},

			"authors": &graphql.Field{
				Type:        graphql.NewList(authorType),
				Description: "Get list of all authors.",
				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					// ToDo deal with ok
					fmt.Println("About to query authors")
					authors, err := queryAuthors(db)
					checkErr(err)

					return authors, nil
				},
			},

			// Posts
			"post": &graphql.Field{
				Type:        postType,
				Description: "Get a post.",
				Args: graphql.FieldConfigArgument{
					"id": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.Int),
					},
				},
				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					// ToDo deal with ok
					postID, _ := params.Args["id"].(int)

					post, err := queryPost(db, postID)
					checkErr(err)

					return post, nil
				},
			},

			"posts": &graphql.Field{
				Type:        graphql.NewList(postType),
				Description: "Get list of posts.",
				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					// ToDo deal with ok

					posts, err := queryPosts(db)
					checkErr(err)

					return posts, nil
				},
			},
		},
	})

	rootMutation := graphql.NewObject(graphql.ObjectConfig{
		Name: "RootMutation",
		Fields: graphql.Fields{
			// Author
			"createAuthor": &graphql.Field{
				Type:        authorType,
				Description: "Create a new author.",
				Args: graphql.FieldConfigArgument{
					"name": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.String),
					},
					"email": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.String),
					},
				},

				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					name, _ := params.Args["name"].(string)
					email, _ := params.Args["email"].(string)

					author, err := createAuthor(db, name, email)
					checkErr(err)

					return author, nil
				},
			},
			"deleteAuthor": &graphql.Field{
				Type:        graphql.Boolean,
				Description: "Delete post.",
				Args: graphql.FieldConfigArgument{
					"id": &graphql.ArgumentConfig{
						Type: graphql.Int,
					},
				},
				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					authorID, _ := params.Args["id"].(int)

					success, err := deleteAuthor(db, authorID)
					checkErr(err)

					return success, nil
				},
			},

			// Post
			"createPost": &graphql.Field{
				Type:        postType,
				Description: "Create a new post.",
				Args: graphql.FieldConfigArgument{
					"title": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.String),
					},
					"content": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.String),
					},
					"authorID": &graphql.ArgumentConfig{
						Type: graphql.NewNonNull(graphql.Int),
					},
				},

				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					title, _ := params.Args["title"].(string)
					content, _ := params.Args["content"].(string)
					authorID, _ := params.Args["authorID"].(int)

					author, err := createPost(db, title, content, authorID)
					checkErr(err)

					return author, nil
				},
			},
			"deletePost": &graphql.Field{
				Type:        graphql.Boolean,
				Description: "Delete post.",
				Args: graphql.FieldConfigArgument{
					"id": &graphql.ArgumentConfig{
						Type: graphql.Int,
					},
				},
				Resolve: func(params graphql.ResolveParams) (interface{}, error) {
					postID, _ := params.Args["id"].(int)

					success, err := deletePost(db, postID)
					checkErr(err)

					return success, nil
				},
			},
		},
	})

	schema, _ := graphql.NewSchema(graphql.SchemaConfig{
		Query:    rootQuery,
		Mutation: rootMutation,
	})

	graphqlHandler = handler.New(&handler.Config{
		Schema:   &schema,
		Pretty:   true,
		GraphiQL: true,
	})

}

func GraphqlFunc(w http.ResponseWriter, r *http.Request) {
	graphqlHandler.ServeHTTP(w, r)
}

func main() {
	http.Handle("/graphql", graphqlHandler)
	
	fmt.Printf("Starting server server on port %s...\n", appPort)
	err := http.ListenAndServe(fmt.Sprintf(":%s", appPort), nil)
	checkErr(err)
}