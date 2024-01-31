## Słowny opis wymagań

UKB - Użytkownik konta bankowego - klient banku posiadający w nim konto.

\begin{figure}[hbtp]
    \makebox[\textwidth][c]{
        \includegraphics[width=\paperwidth]{./docs/requirements_diagram.png}
    }
    \caption{Diagram wymagań}
\end{figure}

### Wymagania funkcjonalne

0. Potencjalny klient banku może zarejestrować nowe konto bankowe.
0. UKB ma wgląd do stanu swojego konta bankowego w PLN.
0. UKB ma wgląd do przypisanych do konta i aktywnych lokat.
0. UKB może przelewać pieniądze ze swojego konta bankowego na konto bankowe innego UKB tego samego systemu.
0. UKB może przelewać pieniądze ze swojego konta bankowego na konto bankowe innego UKB zewnętrzego systemu bankowego.
0. UKB może zakładać lokaty bankowe o określonym oprocentowaniu określonym w katalogu lokat banku.
0. UKB może włączyć lub wyłączyć opcję przewalutowanie przelewów ze swojego konta bankowego.
0. UKB ma prawo złożyć podanie elektroniczne o zamknięcie konta bankowe.
0. UKB może zamknąć lokatę przed terminem jej zakończenia.
0. UKB może stworzyć cykliczne zlecenie przelewu ze swojego konta.
0. UKB może edytować istniejące cykliczne zlecenie przelewu ze swojego konta.
0. UKB może zamknąć cykliczne zlecenie przelewu ze swojego konta.
0. UKB ma wgląd do historii wpływów i wypływów finansowych ze swojego konta.
0. UKB może rozpocząć, prowadzić i zakończyć chat z chatbotem w celu uzyskania pomocy i/lub oferty banku.

### Wymagania niefunkcjonalne

0. Podczas rejestracji trzeba podać: imię, nazwisko, PESEL, numer dokumentu tożsamości, adres do korespondencji, datę urodzenia.
0. Dostęp do konta UKB wymaga autoryzacji przez podanie danych dostępowych: loginu, hasła i kodu autoryzacji dwustopniowej (2FA).
0. System obsługuje po stronie użytkownika język polski m.in., generując komunikaty o błędach czy udostępniając interfejs użytkownika w tym języku.
0. Przelew/cykliczne zlecenie między UKB są możliwe tylko pod warunkiem posiadania wystarczających środków na koncie.
0. Przelew do banku, w którym waluta jest inna niż PLN jest możliwy wyłącznie, kiedy UKB ma włączoną opcję przewalutowania.
0. Warunkiem złożenia podania elektronicznego o zamknięcie konta jest nieposiadanie aktywnych lokat.
0. Zamknięcie przedterminowe wiąże się z utratą odsetek przez UKB.
0. Chatbot posiada dostępność 24 godziny na dobę przez 7 dni w tygodniu.
0. Implementacja systemu odbywa się w języku Java.
