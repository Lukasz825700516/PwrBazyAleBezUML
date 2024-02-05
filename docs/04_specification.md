# Projekt bazy danych

Utworzono projekt bazy danych mający na celu umożliwić jednoznaczne
przechowywanie informacji o stanie kont użytkowników banku.

\begin{figure}[hbtp]
    \makebox[\textwidth][c]{
        \includegraphics[width=\paperwidth]{./docs/erd.png}
    }
    \caption{Diagram relacji encji}
\end{figure}



## Implementacja bazy danych

System bankowy używa zaprojektowanej bazy danych zaimplemnetowanej na systemie bazodanowym postgres.
Aby obniżyć koszty utrzymania, baza danych będzie skonteneryzowana i uruchamiana przez system podman,
w celu uruchomiania jej bez potrzeby posiadania uprawnień administracyjnych.

Serwer postgres będzie uruchomiony z obrazu bazy postgres opartego o alpine linux, aby maksymalnie 
zmniejszyć rozmiar kontenera, oraz zmniejszając możliwości środowiska które on udostępnia, w celu
zminimalizowania obszaru który jest podatny na ataki.

Aby umożliwić sprawne tworzenie kopii zapasowych bazy danych, oraz zapewnić trwałość danych niezależną
od kontenera z której uruchomiony jest serwer, katalog przechowujący pliki bazodanowe serwera 
mają być podmontowanymi voluminami.

Aby zwiększyć izolację między bazą danych a użytkownikami, baza jest skonfigurowana domyślnie aby,
dostęp do niej był możliwy tylko z tworzonej przez podmana sieci wewnętrznej, w której znajduje się
również serwer pełniący rolę inferfejsu graficznego systemu bankowego.

System zarządzania kontenerami	podman 
------------------------------  ----------------------------------- ---------
Obraz                           docker.io/postgres:12.17-alpine3.19
Podmontowane katalogi           kontener                            system
                                /var/lib/postgresql/data            volumin

Szkielet bazy danych, tabele, wymagania, mogą być zainicjalizowane prosto przy użyciu dołączonego pliku
baza.sql. Aby po raz pierwszy utworzyć bazę, należy uruchomić serwer bazo danowy, a następnie podłączyć
się do niego, np. przy użyciu standardowego programu psql do użytkownika admin, z hasłem password do bazy
bazy i wykonać zawartość dołączonego pliku.

Plik baza.sql został wygenerowany narzędziem pq\_dump służącym do generowania zapytań sql do odtwarzania 
całej bazy danych. Pierwotna baza została utworzona na podstawie zaprojektowanego diagramu relacji encji.

Baza ma zdefiniowanego użytkownika admin, i użytkownika system, który pozwala serwerowi bankowemu
na modyfikację i wstawianie nowych rekordów.

Przed wdrożeniem systemu, zalecana jest zmiana hasła kontom bazodanowym.

użytkownik | dostęp
-------|---------------
admin | wszystko, wszędzie
system | odczyt, zapis, wszędzie

## Polecenia SQL

Niżej zaprezentowane są komendy SQL, przy których utworzono bazę danych. 

- tabele
```sql
CREATE TABLE public.konto (
    id integer NOT NULL,
    nr numeric(24,0) NOT NULL,
    srodki integer NOT NULL
);

CREATE TABLE public.lokata (
    lokata integer NOT NULL,
    konto integer NOT NULL,
    srodki integer NOT NULL,
    data date NOT NULL
);

CREATE TABLE public.adresowe (
    id integer NOT NULL,
    mieszkanie character varying(255),
    budynek character varying(255) NOT NULL,
    ulica character varying(255),
    miejscowosc character varying(255) NOT NULL,
    poczta integer
);

CREATE TABLE public.kontaktowe (
    id integer NOT NULL,
    email character varying(255),
    teelefon integer
);

CREATE TABLE public.logowania (
    id integer NOT NULL,
    login character varying NOT NULL,
    haslo character varying NOT NULL,
    autoryzacja2e character varying NOT NULL,
    zaufany character varying NOT NULL
);

CREATE TABLE public.lokaty (
    id integer NOT NULL,
    oprocentowanie integer NOT NULL,
    dlugosc interval NOT NULL
);

CREATE TABLE public.osobowe (
    id integer NOT NULL,
    imie character varying(255) NOT NULL,
    imie2 character varying(255),
    nazwisko character varying(255) NOT NULL,
    data date NOT NULL,
    pesel integer NOT NULL,
    dokument character varying(9) NOT NULL,
    termin date NOT NULL,
    can integer NOT NULL
);

CREATE TABLE public.przelew (
    nadawca numeric(24,0) NOT NULL,
    adresat numeric(24,0) NOT NULL,
    kwota integer NOT NULL,
    data timestamp without time zone NOT NULL,
    tytul character varying(255) NOT NULL
);

CREATE TABLE public.przelewc (
    id integer NOT NULL,
    nadawca numeric(24,0) NOT NULL,
    adresat numeric(24,0) NOT NULL,
    kwota integer NOT NULL,
    data timestamp without time zone NOT NULL,
    okres interval NOT NULL,
    faza timestamp without time zone NOT NULL,
    tytul character varying(255) NOT NULL
);

CREATE TABLE public.przelewz (
    id integer NOT NULL,
    nadawca numeric(24,0) NOT NULL,
    adresat numeric(24,0) NOT NULL,
    kwota integer NOT NULL,
    data timestamp without time zone NOT NULL,
    tytul character varying(255) NOT NULL
);

CREATE TABLE public.usb (
    d_logowania integer NOT NULL,
    d_osobowe integer NOT NULL,
    d_adresowe integer NOT NULL,
    konto integer NOT NULL,
    d_kontaktowe integer NOT NULL
);

CREATE TABLE public.konto (
    id integer NOT NULL,
    nr numeric(24,0) NOT NULL,
    srodki integer NOT NULL
);

CREATE TABLE public.lokata (
    lokata integer NOT NULL,
    konto integer NOT NULL,
    srodki integer NOT NULL,
    data date NOT NULL
);

CREATE TABLE public.adresowe (
    id integer NOT NULL,
    mieszkanie character varying(255),
    budynek character varying(255) NOT NULL,
    ulica character varying(255),
    miejscowosc character varying(255) NOT NULL,
    poczta integer
);

CREATE TABLE public.kontaktowe (
    id integer NOT NULL,
    email character varying(255),
    teelefon integer
);

CREATE TABLE public.logowania (
    id integer NOT NULL,
    login character varying NOT NULL,
    haslo character varying NOT NULL,
    autoryzacja2e character varying NOT NULL,
    zaufany character varying NOT NULL
);
```

- Uprawnienia dla użytkownika system

```sql
GRANT INSERT ON TABLE public.konto TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.lokata TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.adresowe TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.kontaktowe TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.logowania TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.osobowe TO system;
GRANT SELECT,INSERT ON TABLE public.przelew TO system;
GRANT SELECT,INSERT,DELETE ON TABLE public.przelewc TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.usb TO system;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.uzytkownicy TO system;
```

- Procedury

```sql
create or replace procedure run_reccurent_payments()
language plpgsql
as $$ 
 declare my_cur cursor for 
	select
		nadawca,
		adresat,
		kwota,
		tytul,
		extract(epoch from data),
		extract(epoch from faza),
		extract(epoch from okres)
	from przelewc;

 declare r_nadawca numeric(24);
 declare r_adresat numeric(24);
 declare r_kwota int;
 declare r_tytul varchar;
 declare r_data numeric;
 declare r_faza numeric;
 declare r_okres numeric;
begin
 open my_cur;
 fetch my_cur into r_nadawca, r_adresat, r_kwota, r_tytul, r_data, r_faza, r_okres;
 while FOUND loop
  if (r_data - r_faza) / r_okres >= 1 then
   call przelew(r_nadawca, r_adresat, r_kwota, r_tytul);
  end if;
  fetch my_cur into r_nadawca, r_adresat, r_kwota, r_tytul, r_data, r_faza, r_okres;
 end loop;
 close my_cur;
end; $$;
```

```sql
CREATE PROCEDURE public.przelew(IN p_nadawca numeric, IN p_adresat numeric, IN p_kwota integer, IN p_tytul character varying)
    LANGUAGE plpgsql
    AS $$
begin
 if exists (select 1 from konto where nr=p_nadawca and srodki >= p_kwota)  then
   insert into przelew(nadawca, adresat, kwota, data, tytul) values (p_nadawca, p_adresat, p_kwota, NOW(), p_tytul);
   update konto set srodki=srodki-p_kwota where konto.nr = p_nadawca;
  end if;
end; $$;
```

```sql
CREATE PROCEDURE public.run_reccurent_payments()
    LANGUAGE plpgsql
    AS $$ 
 declare my_cur cursor for 
select
nadawca,
adresat,
kwota,
tytul,
extract(epoch from data),
extract(epoch from faza),
extract(epoch from okres)
from przelewc;

 declare r_nadawca numeric(24);
 declare r_adresat numeric(24);
 declare r_kwota int;
 declare r_tytul varchar;
 declare r_data numeric;
 declare r_faza numeric;
 declare r_okres numeric;
begin
 open my_cur;
 fetch my_cur into r_nadawca, r_adresat, r_kwota, r_tytul, r_data, r_faza, r_okres;
 while FOUND loop
  if (r_data - r_faza) / r_okres >= 1 then
   call przelew(r_nadawca, r_adresat, r_kwota, r_tytul);
  end if;
  fetch my_cur into r_nadawca, r_adresat, r_kwota, r_tytul, r_data, r_faza, r_okres;
 end loop;
 close my_cur;
end; $$;
```

```sql
CREATE PROCEDURE public.close_lokata(IN p_konto integer, IN p_lokata integer)
    LANGUAGE sql
    BEGIN ATOMIC
 UPDATE public.konto SET srodki = (konto.srodki + ( SELECT lokata.srodki
            FROM public.lokata
           WHERE ((lokata.konto = close_lokata.p_konto) AND (lokata.lokata = close_lokata.p_lokata))))
   WHERE (konto.id = close_lokata.p_konto);
 DELETE FROM public.lokata
   WHERE ((lokata.lokata = close_lokata.p_lokata) AND (lokata.konto = close_lokata.p_konto));
END;
```


- Klucze główne i obce

```sql
ALTER TABLE ONLY public.adresowe
    ADD CONSTRAINT adresowe_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.konto
    ADD CONSTRAINT fk_konto_nr UNIQUE (nr);
ALTER TABLE ONLY public.kontaktowe
    ADD CONSTRAINT kontaktowe_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.konto
    ADD CONSTRAINT konto_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.logowania
    ADD CONSTRAINT logowania_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.lokaty
    ADD CONSTRAINT lokaty_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.osobowe
    ADD CONSTRAINT osobowe_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.przelewc
    ADD CONSTRAINT przelewc_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.przelewz
    ADD CONSTRAINT przelewz_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.przelewc
    ADD CONSTRAINT fk_przelewc_adresat FOREIGN KEY (adresat) REFERENCES public.konto(nr);
ALTER TABLE ONLY public.lokata
    ADD CONSTRAINT fklokatakonto FOREIGN KEY (konto) REFERENCES public.konto(id);
ALTER TABLE ONLY public.lokata
    ADD CONSTRAINT fklokatalokata FOREIGN KEY (lokata) REFERENCES public.lokaty(id);
ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbadresowe FOREIGN KEY (d_adresowe) REFERENCES public.adresowe(id);
ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbkontaktowe FOREIGN KEY (d_kontaktowe) REFERENCES public.kontaktowe(id);
ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbkonto FOREIGN KEY (konto) REFERENCES public.konto(id);
ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusblogowania FOREIGN KEY (d_logowania) REFERENCES public.logowania(id);
ALTER TABLE ONLY public.usb
    ADD CONSTRAINT fkusbosobowe FOREIGN KEY (d_osobowe) REFERENCES public.osobowe(id);
```

- Sekwencyje

```sql
CREATE SEQUENCE public.adresowe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.kontaktowe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.konto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.logowania_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.lokaty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.osobowe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.przelewc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
CREATE SEQUENCE public.przelewz_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
```


## Testy bazy danych

Do bazy danych utworzono zautomatyzowane testy jednostkowe sprawdzające jest spójność.
Testy zostały zaprogramowane w języku go. Aby uruchomić testy, należy wykonać

```bash
go test 
```

Przygotowano trzy rodzaje testów:

- Test czy da się użyć bazy.

Niżej przygotowano przykładowy test i test do niego przeciwny

```go 
// język go 

func TestTransferIllegalAddress(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
        host, port, user, password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`call przelew($1, $2, $3, $4))`,
    "ble", "ble", int(1 * 100), "Shoudl not work"); err == nil {
		t.Fatalf("Could execute malformend command")
	} 
}

func TestTransfer(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
    host, port, user, password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`call przelew($1, $2, $3, $4)`,
    "000011112222333344445555",
    "000011112222333344445556",
    int(1 * 100), "Shoudl work"); err != nil {
		t.Fatalf("%v", err)
	} 
}
```

- Test czy prawa dostępu są poprawne.

```go 
// język go 

func TestAccessIllegal(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
    host, port, service_user, service_password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`delete from przelew`); err == nil {
		t.Fatalf("Could execute illegal command")
	} 
}

func TestAccess(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
    host, port, service_user, service_password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`call przelew($1, $2, $3, $4)`,
    "000011112222333344445555",
    "000011112222333344445556",
    int(1 * 100), "Shoudl work"); err != nil {
		t.Fatalf("%v", err)
	} 
}
```

- Test wydajnościowy w przy dużym wypełnieniu bazy, w zależności od liczby zapytań.

Bazę wypełniono danymi

```go
// język go

func TestOnce(t *testing.T) {
	return; // return aby nie dodawać więcej danych niż już dodano
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
    host, port, service_user, service_password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	for i := 0; i < 100000; i++ {
		if _, err := db.Exec(`call przelew($1, $2, $3, $4)`, "000011112222333344445555",
        "000011112222333344445556", int(1 * 1), "Shoudl work"); err != nil {
			t.Fatalf("%v", err)
		} 
	}
}
```

A następnie

```go 
// język go
func TestSelect(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
    host, port, service_user, service_password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Query(`select * from przelew`); err != nil {
		t.Fatalf("%v", err)
	} 
}
```

Testy wydajnościowe pokazały, że czas wykonywania apytania rośnie liniowo i dla 16k rekordów, selekt wykonuje się 0.04s;
odczyt i przetworzenie 16k rekordów do formatu HTML zajmuje około 5s, niezależnie dla małej liczby zapytań na sekundę (2/s).
40k wykonuje się 0.05s, a odczyt i przetworzenie do formatu HTML około 25s. Jak widać, czas przygotowania zapytania jest 
zawsze większy niż szybkość jego przetwarzania.


# Specyfikacja
## Specyfikacja techniczna serwera systemu bankowego

Interakcja z systemem bankowym ma opierac się o protokół HTTP, mający zapewnić możliwość połączenia
się każdego użądzenia komputerowego posiadającego kartę sieciową, bez żadnej dodatkowej konfiguracji.

Sam serwer jest zaprojektowany w języku golang, jego standardowej biblioteki i modułu gorilla/sessions wraz
z gorilla/csrf mające zapewnić wystarczający poziom bezpieczeństwa przed zautomatyzowanymmi atakammi
na udostępniany interfejs.

Dany język i zestaw bibliotek zostały wybrane ze względu na prostotę składni, jawną obsługę błędów i 
architekturę wspierającą tworzenie programów asynchronicznych na poziomie samej składni języka.

Działanie samego serwer opiera się o przyjmowanie zapytań HTTP, i w zależności od url w nich zawartego
wraz z typem zapytania (GET, POST lub DELETE) sprawdzania danych sesji użytkownika, przesłanego formularza
i wykonywanai odpowiedniego zapytanai sql jeśli wszystko jest ok.

Każda obsługa zapytania kończy się przesłaniem odpowiedniej odpowiedzi HTTP zapierającej przekierowanie, lub
prekazującej minimalistyczny kod HTML zawierający dane których użytkownik żądał. Aby zwiększyć interaktywność
intergejsu, strona główna interfejsu zawiera dołączenie biblioteki htmx, umożliwiającej po stronie klienta
dynamiczne ładowanie danych z serwera, przy pomocy dodawania do zwykłych tagów HTML specjalnych atrybutów
zwiększających ich interaktywność.

## Specyfikacja infrastruktury systemu bankowego

Cały system jest oparty o technologię konteneryzacji opartą o kontenery OCI, aby umożliwić prostą instalację i integrację systemu
niezależnie od maszyn na których ma być on hostowany.

Sam system jest zdefiniowany w pliku compose, umożliwiając jego całkowitą reprodukcję i definiując środowisko
w którym ma być on uruchamiany.

System nie ma być bezpośrednio łączony z internetem, do infrastruktury umożliwiającej działanie systemu
powinien wchodzić serwer reverse proxy z load balancerem, który będzie wymuszał komunikację szyfrowaną
między internetem a infrastrukturą, oraz umożliwiał skalowanie w szerz systemu bankowego.

### Stawianie serwera

```bash
podman-compose up
```

Jeśli baza danych nie została jeszcze zainicjalizowana, w kontenerze bazy

```bash
psql -U admin -d bazy < baza.sql
```

## Specyfikacja kliencka

Każdy klient banku ma udostępniony interfejs webowy do banku. Interfejs webowy jest zaprojektowany w 
sposób minimalistyczny, umożliwiający proste zarządzanie stanem konta użytkownika, jak i minimalizujący 
transfer danych między użytkownikiem a systemem bankowym.

Minimalistyczny interfejs ma również zapewnić łatwość tworzenia różnych nakładek graficznych przez
osoby trzecie, w wypadku gdyby mmiały one specjalne potrzeby wynikające z ich stanu zdrowotnego.

Wszystkie funkcje bankowe wymagają uprzedniego poprawnego wypełnienia formularza logowania do systemu bankowego.

W przypadku podania błędnych danych przez użytkownika, zostaje on wylogowany i zmuszany do ponownego zalogowania się
aby chronić jego dane przez neupowarznionym dostępem.

### Mini instrukcja obsługi

- Aby utworzyć lokatę, kliknij przycisk załóż [obrazek](Tworzenie lokat)
obrazek \ref{l}

![Tworzenie lokat \label{l}](./docs/lokata.png)

- Aby wpłacić/wypłacić pieniądze z lokaty, wpisz kwotę do przelania (1), i kliknij przelej (2)
obrazek \ref{lp}

![Przelewanie na lokate \label{lp}](./docs/lokata_przelej.png)

- Aby wykonać przelew, wpisz 26 cyfrowy numer konta bankowego adresata (2), wpisz kwotę przelewu (1), wpisz tytuł
przelewu (3) i kliknij przrycisk (4)
obrazek \ref{p}

![Przelew \label{p}](./docs/przelew.png)

## Podsumowanie użytych technologii


strona | język | oprogramowanie | cel
------|-----|------|-------------
serwer|golang|serwer bankowy|utworzenie bezpiecznego interfejsu do komunikacji między bazą danych a klientem
serwer|golang|pq|połączenie z postgres
serwer|golang|gorilla/sessions|zapewnienie sesji przeglądania dla użytkowników
serwer|golang|gorilla/csrf|zabezpieczenie formularzy przed atakiem cross site request forgery
serwer|golang|templ|generowanie funkcji na posdstawie szablonów HTML generujących HTML z podanymi parametrami
infrastruktura|niedotyczy|postgres|używana baza danych
infrastruktura|compose|niedotyczy|zapewnienie jednoznaczej i przenośnej definicji systemu bankowego
infrastruktura|niedotyczy|podman|zarządzanie kontenerami
infrastruktura|niedotyczy|reverse proxy + load balancer przyjmujący połączenia tls|umożliwienie rozszerzania w szerz infrastruktury
klient|javascript|htmx|zapewnienie interaktywnej strony, bez ciągłego odświerzania

## Biblioteki

nazwa | wersja
--------|-----
go   |  1.21.5
github.com/lib/pq | v1.10.9
github.com/gorrila/csrf | v1.8.2
github.com/gorrila/session | v1.2.9
github.com/a-h/templ | v0.2.513


## Rozwiązania technologiczne


Obsługa endpointa na przykładzie wyświetlania lokat przypisanych do konta

- Walidacja danych 

```go
// język go
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
``` 

- Odczyt danych z dazy banych.

```go
// język go
    rows, err := db.Query(`select 
lokata.lokata, lokata.srodki, extract(epoch from lokata.data)::int, 
extract(epoch from (lokata.data + lokaty.dlugosc))::int, lokaty.oprocentowanie
from lokata
inner join lokaty on lokata.lokata=lokaty.id
where lokata.konto = $1`, account)
    if err != nil {
        fmt.Printf("%v", err)
        http.Redirect(w, r, "/", http.StatusSeeOther)
        return
    }
```

- Wyświetlanie HTML zawierającego zwrócone rekordy

```go
// język go
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
}
```

# Podsumowanie

System świadczy podstawowe wymagania w temacie bezpieczeństwa, bezpiecznie
przechowując dane użytkowników i ich środki.

System opiera się na interfejsie dostarczanym przez serwer HTTP,
umożliwiającym na interakcje z bazą danych. Sama architektura systemu
jest otwarta na rozszeżanie jej w ramach rosnących wymagań klienta.

Baza danych, utworzony program są dostępne na serwisie 
[github.com github.com/Lukasz825700516/PwrBazyAleBezUML](github.com/Lukasz825700516/PwrBazyAleBezUML).

## Wnioski

Wybór języka go, wypecjalizowanego do szybkiego tworzenia aplikacji sieciowych faktycznie 
przyśpieszył pracę nad implementacją serwera HTTP, zmniejszając do minimum czas wymagany do skonfigurowania
poprawnie połączeń i ich optymalnej obsługi, biorąc pod uwagę wcześniejsze doświadczenie zespołu programistycznego w językach
programowania takich jak PHP, Rust, Javascript, C.

Realizacja projektu pokazała również, że etap projektowania powinien przewidywać kilka 
faz podczas których opracowany projekt będzie sprawdzony pod kątem wymagań narzucanych przez jego impleentację,
tak aby po wykryciu problemu, dało się zmodyfikować tylko jego małą część, zamiast wszyskiego.

W czasie pisania oprogramowania, skupienie się na samej funkcjonalności jednocześnie pozostawiając 
łatwy do edycji szkielet interfejsu użytkownika, przez udostępnienie interfejsu HTML obsługiwanego
przez zwykłe zapytania GET i POST, umożliwiły skrócenie cyklu rozwoju całego oprogramowania do minimum.

# Literatura, głównie dokumentacja

- [Dokumentacja go go.dev](https://go.dev).
- [Dokumentacja templ github.com/a-h/templ](https://github.com/a-h/templ).
- [Dokumentacja gorrila gorilla.github.io](https://gorilla.github.io/).
- [Dokumentacja postgres www.postgresql.org/docs/](https://www.postgresql.org/docs/).
- [Podman strona główna podman.io](https://podman.io/).
- [HTMX strona główna htmx.org](https://htmx.org/).
