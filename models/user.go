package models

import (
	"fmt"
	"time"
)

type Srodki interface {
	SrodkiStr() string
}

type Osobowe struct {
	Id int
	Imie string
	Imie2 string
	Nazwisko string
	Data int
	Pesel int
	Dokument string
	Termin int
	Can int
}

type Konto struct {
	Id int
	Nr []int
	Srodki int
}

func (o *Konto) NrKonta() string {
	c := make([]rune, 24)
	for i := range c {
		c[i] = rune(o.Nr[i] + '0')
	}
	return string(c)
}

func (o *Konto) SrodkiStr() string {
	return fmt.Sprintf("%v.%v", o.Srodki / 100, o.Srodki % 100)
}

type Lokata struct {
	Lokata int
	Konto int
	Srodki int
	Data time.Time
	Koniec time.Time
}

func (o *Lokata) SrodkiStr() string {
	return fmt.Sprintf("%v.%v", o.Srodki / 100, o.Srodki % 100)
}

type LokataTyp struct {
	Id int 
	Oprocentowanie int 
	Dlugosc int
}
