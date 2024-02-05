# Bazy danych

Projekt - obsługa konta bankowego

Przygotowali: Łukasz Mędrek, Maciek Szymczak

# Obrazek, prezentacja, interfejs

![Interfejs graficzny w akcji](./docs/prezentacja/wow.png)

# Daza banych

![Daza banych](./docs/erd.png)

# Technologie

|
-----|---------------
go | serwer
postgres | baza
html | klient
htmx | połączenie klienta z serwerem

# Wybór serwera

![go logo](./docs/prezentacja/golang.png)

# Zalety

- Prosty
- Szybki
- Zaprojektowany pod serwery

# Wady

- Prosty

# Wybór dazy banych

![postgres logo](./docs/prezentacja/postgres.png)

# Zalety

- Znany
- Standard sql
- Możliwość skalowania bazy

# Wady

- Skomplikowany

# Wybór interfejsu

![html logo](./docs/prezentacja/html.jpg)

# Zalety

- Wspierany w przeglądarkach internetowych
- Czytelny dla człowieka i maszyny

# Wady

- Brak

# Integracja interfejsu z serwerem

![htmx logo](./docs/prezentacja/htmx.png)

# Zalety

- Pozwala skupić się na html
- Waży mniej niż losowy obrazek z eportalu

# Wady

- Javascript

# Sposoby obsługi klienta

## Interaktywny (w przeglądarce)

- Klient wypełnia formularz logowania
- Klient klika przycisk wyślij (lub enter)

## Ten drugi

- Klient wysyła zapytanie do strony głównej banku
- Klient wysyła zapytanie POST z danymi do logowania

# Sposoby obsługi klienta

## Interaktywny (w przeglądarce)

- Zalogowany klient trafia na stronę swojego konta

## Ten drugi

- Klient wysyła zapytania GET z ciasteczkami o konkretne dane swojego konta

# Wdrożenie

![podman logo](./docs/prezentacja/podman.png)

# Zalety

- Domyślnie bez roota

# Wady

- Niektóre obrazy z dockerhuba wymagają roota (wtf)
