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
	"time"

	"github.com/a-h/templ"
)

type LokatyControler struct {
	lokataTemplate func(models.LokataTyp) templ.Component
}

func NewLokatyControler() LokatyControler {
	return LokatyControler{
		lokataTemplate: templates.Lokata,
	}
}

func (o *LokatyControler) Add(db *sql.DB) {
	http.HandleFunc("/lokaty", func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseForm(); err != nil {
			log.Fatal(err)
		}

		id, err := strconv.ParseInt(r.FormValue("id"), 10, 0)
		if err != nil {
			rows, err := db.Query(`select id, oprocentowanie,
(
extract(year from dlugosc) * 12 +
extract(month from dlugosc)
)
from lokaty`)
			if err != nil {
				fmt.Printf("%v", err)
				http.Redirect(w, r, "/", http.StatusSeeOther)
				return
			}
			fmt.Fprintf(w, "<html><body>")
			for rows.Next() {
				var (
					id int
					oprocentowanie int
					dlugosc int
				)
				rows.Scan(&id, &oprocentowanie, &dlugosc);
				
				if err := templates.Lokata(models.LokataTyp{
					Id: id,
					Oprocentowanie: oprocentowanie,
					Dlugosc: dlugosc,
				}).Render(context.Background(), w); err != nil {
					log.Fatal(err)
				}
			}
			fmt.Fprintf(w, "</body></html>")

			return
		}

		fmt.Println("a")
		cookie, err := r.Cookie("account_id")
		if err != nil {
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		fmt.Println("b")
		account, err := strconv.ParseInt(cookie.Value, 10, 0)
		if err != nil {
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		tx, err := db.BeginTx(context.Background(), nil)
		if err != nil {
			log.Fatal(err)
		}

		var c int
		if err := tx.QueryRow(`select count(*) from lokata 
inner join usb on usb.konto = lokata.konto
inner join logowania on usb.d_logowania = logowania.id
where lokata.lokata=$1 and logowania.id = $2`, id, account).Scan(&c); err != nil {
			tx.Rollback()
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		} else if c > 0 {
			tx.Rollback()
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		if _, err := tx.Exec("insert into lokata values ($1, $2, 0, current_timestamp)", id, account); err != nil {
			tx.Rollback()
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		} 

		if err := tx.Commit(); err != nil {
			log.Fatal(err)
		}

		fmt.Println("d")
		http.Redirect(w, r, "/account", http.StatusSeeOther)
		return
	})

	http.HandleFunc("/moje_lokaty", func(w http.ResponseWriter, r *http.Request) {
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

		rows, err := db.Query(`select 
lokata.lokata, lokata.srodki, extract(epoch from lokata.data)::int, extract(epoch from (lokata.data + lokaty.dlugosc))::int, lokaty.oprocentowanie
from lokata
inner join lokaty on lokata.lokata=lokaty.id
where lokata.konto = $1`, account)
		if err != nil {
			fmt.Printf("%v", err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		fmt.Fprintf(w, "<html><body>")
		for rows.Next() {
			var (
				lokata int
				srodki int
				data int64
				koniec int64
				oprocentowanie int
			)
			rows.Scan(&lokata, &srodki, &data, &koniec, &oprocentowanie);
			
			fmt.Println(data, koniec)
			if err := templates.MojaLokata(
				models.Lokata{
					Lokata: lokata,
					Srodki: srodki,
					Data: time.Unix(data, 0),
					Koniec: time.Unix(data, 0),
				},
				models.LokataTyp{
					Oprocentowanie: oprocentowanie,
				},
			).Render(context.Background(), w); err != nil {
				log.Fatal(err)
			}
		}
		fmt.Fprintf(w, "</body></html>")
	})

	http.HandleFunc("/przelej_lokata", func(w http.ResponseWriter, r *http.Request) {
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



		lokata, err := strconv.ParseInt(r.FormValue("lokata"), 10, 0)
		if err != nil {
			log.Print("2222popusted")
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		} 
		kwota, err := strconv.ParseFloat(r.FormValue("kwota"), 0)
		if err != nil {
			log.Print("popusted")
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		} 

		if int(kwota * 100) > 999999999 {
			log.Print("kwota duża", kwota, kwota > 999999999)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		if int(kwota * 100) < 0 {
			log.Print("kwota mała")
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}
		
		
		var (
			ok bool
		)
		if err := db.QueryRow(`
select 
	srodki > $2
from konto 
	inner join usb on usb.konto=konto.id 
	inner join logowania on usb.d_logowania=logowania.id 
where logowania.id=$1`, account, int(kwota * 100)).Scan(&ok); err != nil {
			log.Fatal(err)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		} else if !ok {
			log.Printf("ok: %v", ok)
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		tx, err := db.BeginTx(context.Background(), nil)
		if err != nil {
			log.Fatal(err)
		}

		if _, err := tx.Exec(`update lokata 
set srodki = srodki + $1
from usb
	inner join logowania on usb.d_logowania=logowania.id 
where lokata.lokata=$2 and logowania.id=$3 and usb.konto=lokata.konto
		`, int(kwota * 100), lokata, account); err != nil {
			log.Print("aaa?")
			tx.Rollback()
			log.Fatal(err)
		}
		if _, err := tx.Exec(`update konto 
set srodki = srodki - $1
from usb
	inner join logowania on usb.d_logowania=logowania.id 
where logowania.id=$2 and usb.konto=konto.id  
		`, int(kwota * 100), account); err != nil {
			log.Print("bbb?")
			tx.Rollback()
			log.Fatal(err)
		}

		if err := tx.Commit(); err != nil {
			log.Fatal(err)
		}

		http.Redirect(w, r, "/account", http.StatusSeeOther)
	})

	http.HandleFunc("/lokata_zamknij", func(w http.ResponseWriter, r *http.Request) {
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



		lokata, err := strconv.ParseInt(r.FormValue("lokata"), 10, 0)
		if err != nil {
			log.Print("2222popusted")
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		} 
		
		tx, err := db.BeginTx(context.Background(), nil)
		if err != nil {
			log.Fatal(err)
		}

		if _, err := tx.Exec(`update konto 
set konto.srodki = konto.srodki + lokata.srodki 
from lokata
	inner join usb on usb.konto = lokata.konto
	inner join logowania on usb.d_logowania=logowania.id 
where lokata.lokata=$1 and logowania.id=$2 and usb.konto=lokata.konto
		`, lokata, account); err != nil {
			log.Print("aaa?")
			tx.Rollback()
			log.Fatal(err)
		}
		if _, err := tx.Exec(`delete from lokata 
	inner join logowania on usb.d_logowania=logowania.id 
where lokata.lokata=$1 and logowania.id=$2 and usb.konto=lokata.konto
		`, account); err != nil {
			log.Print("bbb?")
			tx.Rollback()
			log.Fatal(err)
		}

		if err := tx.Commit(); err != nil {
			log.Fatal(err)
		}

		http.Redirect(w, r, "/account", http.StatusSeeOther)
	})

}
