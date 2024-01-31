package models

import (
	"fmt"
	"time"
)

type Przelew struct {
	Id int
	Nadawca []int
	Adresat []int
	Kwota int 
	Data time.Time
	Tytul string
}

func (o *Przelew) SrodkiStr() string {
	return fmt.Sprintf("%v.%v", o.Kwota / 100, o.Kwota % 100)
}
