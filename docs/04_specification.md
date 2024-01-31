# Specyfikacja techniczna bazy danych

System bankowy używa zaprojektowanej bazy danych zaimplemnetowanej na systemie bazodanowym postgres.
Aby obniżyć koszty utrzymania, baza danych będzie skonteneryzowana i uruchamiana przez system podman,
w celu uruchomiania jej bez potrzeby posiadania uprawnień administracyjnych.

Serwer postgres będzie uruchomiony z obrazu bazy postgres opartego o alpine linux, aby maksymalnie 
zmniejszyć rozmiar kontenera, oraz zmniejszając możliwości środowiska które on udostępnia, w celu
zminimalizowania obszaru który jest podatny na ataki.

Aby umożliwić sprawne tworzenie kopii zapasowych bazy danych, oraz zapewnić trwałość danych niezależną
od kontenera z której uruchomiony jest serwer, katalog przechowujący pliki bazodanowe, oraz katalog 
z logami serwera mają być podmontowanymi voluminami.

Aby zwiększyć izolację między bazą danych a użytkownikami, baza jest skonfigurowana domyślnie aby,
dostęp do niej był możliwy tylko z tworzonej przez podmana sieci wewnętrznej, w której znajduje się
również serwer pełniący rolę inferfejsu graficznego systemu bankowego.


System zarządzania kontenerami	podman 
------------------------------  ----------------------------------- ---------
Obraz                           docker.io/postgres:12.17-alpine3.19
Podmontowane katalogi           kontener                            system
                                /var/lib/postgresql/data            volumin

# Specyfikacja techniczna serwera systemu bankowego

Interakcja z systemem bankowym ma opierac się o protokół http, mający zapewnić możliwość połączenia
się każdego użądzenia komputerowego posiadającego kartę sieciową, bez żadnej dodatkowej konfiguracji.

Sam serwer jest zaprojektowany w języku golang, jego standardowej biblioteki i modułu gorilla/sessions wraz
z gorilla/csrf mające zapewnić wystarczający poziom bezpieczeństwa przed zautomatyzowanymmi atakammi
na udostępniany interfejs.

Dany język i zestaw bibliotek zostały wybrane ze względu na prostotę składni, jawną obsługę błędów i 
architekturę wspierającą tworzenie programów asynchronicznych na poziomie samej składni języka.

Działanie samego serwer opiera się o przyjmowanie zapytań http, i w zależności od url w nich zawartego
wraz z typem zapytania (GET, POST lub DELETE) sprawdzania danych sesji użytkownika, przesłanego formularza
i wykonywanai odpowiedniego zapytanai sql jeśli wszystko jest ok.

Każda obsługa zapytania kończy się przesłaniem odpowiedniej odpowiedzi http zapierającej przekierowanie, lub
prekazującej minimalistyczny kod html zawierający dane których użytkownik żądał.

# Specyfikacja infrastruktury systemu bankowego

Cały system jest oparty o technologię konteneryzacji opartą o kontenery OCI, aby umożliwić prostą instalację i integrację systemu
niezależnie od maszyn na których ma być on hostowany.

Sam system jest zdefiniowany w pliku compose, umożliwiając jego całkowitą reprodukcję i definiując środowisko
w którym ma być on uruchamiany.

System nie ma być bezpośrednio łączony z internetem, do infrastruktury umożliwiającej działanie systemu
powinien wchodzić serwer reverse proxy z load balancerem, który będzie wymuszał komunikację szyfrowaną
między internetem a infrastrukturą, oraz umożliwiał skalowanie w szerz systemu bankowego.

# Specyfikacja kliencka

Każdy klient banku ma udostępniony interfejs webowy do banku. Interfejs webowy jest zaprojektowany w 
sposób minimalistyczny, umożliwiający proste zarządzanie stanem konta użytkownika, jak i minimalizujący 
transfer danych między użytkownikiem a systemem bankowym.

Minimalistyczny interfejs ma również zapewnić łatwość tworzenia różnych nakładek graficznych przez
osoby trzecie, w wypadku gdyby mmiały one specjalne potrzeby wynikające z ich stanu zdrowotnego.
