package main

import (
	"database/sql"
	"fmt"
	"testing"
)

const (
	service_user = "system"
	service_password = "password"
)


func TestTransferIllegalAddress(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`call przelew($1, $2, $3, $4)`, "ble", "ble", int(1 * 100), "Shoudl not work"); err == nil {
		t.Fatalf("Could execute malformend command")
	} 
}

func TestTransfer(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`call przelew($1, $2, $3, $4)`, "000011112222333344445555", "000011112222333344445556", int(1 * 100), "Shoudl work"); err != nil {
		t.Fatalf("%v", err)
	} 
}

func TestAccessIllegal(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, service_user, service_password, dbname)

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
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, service_user, service_password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	if _, err := db.Exec(`call przelew($1, $2, $3, $4)`, "000011112222333344445555", "000011112222333344445556", int(1 * 100), "Shoudl work"); err != nil {
		t.Fatalf("%v", err)
	} 
}

func TestSelect(t *testing.T) {
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, service_user, service_password, dbname)

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

func TestOnce(t *testing.T) {
	return;
	psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, service_user, service_password, dbname)

	// open database
	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		t.Fatalf("%v", err.Error())
	}
	defer db.Close()

	
	for i := 0; i < 1000000; i++ {
		if _, err := db.Exec(`call przelew('109010140000071219812874', '000011112222333344445555', 1, 'should work')`); err != nil {
	  		t.Fatalf("%v", err)
		} 
	}
}
