package controlers

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"net/http"
	"pwrbazy/models"
	"pwrbazy/templates"
	"strconv"
	"time"
	"unicode"

	"github.com/a-h/templ"
)

type PrzelewControler struct {
	przelewTemplate func(models.Przelew, models.Konto, models.Konto) templ.Component
}

func NewPrzelewControler() PrzelewControler {
	return PrzelewControler{
		przelewTemplate: templates.Przelew,
	}
}

func (o *PrzelewControler) Add(db *sql.DB) {
	http.HandleFunc("/moje_przelewy", func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseForm(); err != nil {
			log.Fatal(err)
		}

		cookie, err := r.Cookie("account_id")
		if err != nil {
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		account, err := strconv.ParseInt(cookie.Value, 10, 0)
		if err != nil {
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		fmt.Fprintf(w, "<html><body>")
		rows, err := db.Query(`select 
		nadawca, adresat, kwota, extract(epoch from data)::int, tytul from przelew

inner join konto on (przelew.adresat=konto.nr) or (przelew.nadawca=konto.nr)
where konto.id = $1`, account)
		if err != nil {
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		for rows.Next() {
			var (
				nadawca string
				adresat string
				kwota int
				data int64
				tytul string
			)
			rows.Scan(&nadawca, &adresat, &kwota, &data, &tytul);



			n := make([]int, 24)
			for i, c := range nadawca {
				n[i] = int(c - '0')
			}
			a := make([]int, 24)
			for i, c := range adresat {
				a[i] = int(c - '0')
			}
			
			if err := templates.Przelew(
				models.Przelew{
					Nadawca: n,
					Adresat: a,
					Kwota: kwota,
					Data: time.Unix(data, 0),
					Tytul: tytul,
				},
				models.Konto{
					Nr: n,
				},
				models.Konto{
					Nr: a,
				},
			).Render(context.Background(), w); err != nil {
				log.Fatal(err)
			}
		}
		fmt.Fprintf(w, "</body></html>")
	})
	http.HandleFunc("/przelej_forma", func(w http.ResponseWriter, r *http.Request) {
		if err := templates.Przelej().Render(context.Background(), w); err != nil {
			log.Fatal(err)
		}
	})
	http.HandleFunc("/przelej", func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseForm(); err != nil {
			log.Fatal(errors.Join(errors.New("ZZZ"), err))
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		cookie, err := r.Cookie("account_id");
		if err != nil {
			log.Fatal(errors.Join(errors.New("AAA"), err))
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		id, err := strconv.ParseInt(cookie.Value, 10, 0)
		if err != nil {
			log.Fatal(errors.Join(errors.New("bbb"), err))
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		srodki_c := r.FormValue("srodki")
		if err != nil {
			log.Fatal(errors.Join(errors.New("ccc"), err))
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}
		srodki, err := strconv.ParseFloat(srodki_c, 0)
		if err != nil {
			log.Fatal(err)
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		tytul_c := r.FormValue("tytul")

		adresat_c := r.FormValue("adresat")

		adresat := make([]int, 24)
		for i, c := range adresat_c {
			if !unicode.IsNumber(c) {
				log.Fatal(errors.New("Nie numer"))
				http.Redirect(w, r, "/account", http.StatusSeeOther)
				return
			}
			if i > 24 {
				log.Fatal(errors.New("większe niż 24"))
				http.Redirect(w, r, "/account", http.StatusSeeOther)
				return
			}

			adresat[i] = int(c - '0')
		}

		var (
			nadawca string
		)

		db.QueryRow(`select konto.nr from konto
where
konto.id=$1`, id).Scan(&nadawca)

		n := make([]int, 24)
		for i, c := range nadawca {
			n[i] = int(c - '0')
		}	

		if _, err := db.Exec(`insert into przelew(nadawca, adresat, kwota, data, tytul) values (
			$1,
			$2,
			$3,
			Now(),
			$4
		)`, nadawca, adresat_c, int(srodki * 100), tytul_c); err != nil {
			log.Fatal(err)
			http.Redirect(w, r, "/account", http.StatusSeeOther)
			return
		}

		if _, err := db.Exec(`update konto SET 
srodki =
	(select sum(kwota) from przelew inner join konto on konto.nr=przelew.adresat where konto.id = $1) -
	(select sum(kwota) from przelew inner join konto on konto.nr=przelew.nadawca where konto.id = $1) 
where konto.id = $1`, id); err != nil {

			log.Fatal(err)
		}
		

		http.Redirect(w, r, "/account", http.StatusSeeOther)
	})
}

