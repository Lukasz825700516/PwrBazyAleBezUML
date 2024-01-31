package main;

type BankAccount struct {
	id int
	UserData UserData
}

type UserData struct {
	Name        string
	Surname    string
	SecondName *string
}
