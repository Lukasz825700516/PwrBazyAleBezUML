package controlers

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"pwrbazy/models"
	"pwrbazy/templates"
	"strconv"

	"github.com/a-h/templ"
)

type Controler interface {
	Add(*sql.DB)
}

type UserControler struct {
	indexTemplate func(models.Osobowe, models.Konto) templ.Component
}

func NewUserControler() UserControler {
	return UserControler{
		indexTemplate: templates.IndexAccount,
	}
}

func (o *UserControler) Add(db *sql.DB) {
	http.HandleFunc("/login", func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseForm(); err != nil {
			log.Fatal(err)
		}

		login := r.PostForm["login"][0]
		password := r.PostForm["password"][0]

		var (
			id int64
		)
		if err := db.QueryRow("select id from logowania where login=$1 and haslo=$2", login, password).Scan(&id);
		err != nil {
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		http.SetCookie(w, &http.Cookie{Name:"account_id", Value: fmt.Sprintf("%v", id)})
		http.Redirect(w, r, "/account", http.StatusSeeOther)
	})

	http.HandleFunc("/account", func(w http.ResponseWriter, r *http.Request) {
		cookie, err := r.Cookie("account_id");
		if err != nil {
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		id, err := strconv.ParseInt(cookie.Value, 10, 0)
		if err != nil {
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		var (
			srodki int
			imie string
			imie2 string
			nazwisko string
		)
		if err := db.QueryRow(`select srodki, imie, imie2, nazwisko from konto 
inner join usb on usb.konto=konto.id 
inner join osobowe on usb.d_osobowe=osobowe.id 
inner join logowania on usb.d_logowania=logowania.id
where logowania.id=$1`, id).Scan(&srodki, &imie, &imie2, &nazwisko);


		err != nil {
			fmt.Printf("%v %v", err, id)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		if err := templates.IndexAccount(models.Osobowe{
			Imie: imie,
			Imie2: imie2,
			Nazwisko: nazwisko,
		}, models.Konto{
			Srodki: srodki,
		}).Render(context.Background(), w); err != nil {
			log.Fatal(err)
		}
	})
}
