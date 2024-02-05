package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"pwrbazy/controlers"
	"pwrbazy/templates"

	"github.com/a-h/templ"
	_ "github.com/lib/pq"
)

const (
	// host     = "127.0.0.1"
	host     = "127.0.0.1"
	port     = 5432

	// wczytaj dane z FS?
	user     = "admin"
	password = "password"
	dbname   = "bazy"
)

type IndexControler struct {
	indexTemplate func() templ.Component
};

func NewIndexControler() IndexControler {
	return IndexControler{
		indexTemplate: templates.Index,
	}
}


func CheckError(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	defer db.Close()
	CheckError(err)

	// close database
	// Chcę aby zawsze było ppołączenie z Dazą Banych
	// defer db.Close()

	// check db
	err = db.Ping()
	CheckError(err)

	fmt.Println("Connected!")

	uc := controlers.NewUserControler()
	lc := controlers.NewLokatyControler()
	pc := controlers.NewPrzelewControler()

	uc.Add(db)
	lc.Add(db)
	pc.Add(db)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if err := templates.Index().Render(context.Background(), w); err != nil {
			log.Fatal(err)
		}
	})

	if err := http.ListenAndServe(":6969", nil); err != nil {
		log.Fatal(err)
	}
 }
