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


aaa                            bb     c
------------------------------ ------ -
System zarządzania kontenerami | podman | |
|-+-+-|
| Obraz | docker.io/postgres:12.17-alpine3.19 | |
|-+-+-|
|Podmontowane katalogi | kontener | system |
| | /var/lib/postgresql/data | volumin |
