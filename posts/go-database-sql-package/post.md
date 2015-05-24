---
date: 2015-05-23
title: Go - database/sql package 簡介
---

# 前言 #

用 Go 寫程式，要對 SQL 資料庫存取時，就需要依賴 `database/sql` 這個 package。這篇文章將針對這個 package 裡的 API 做介紹，順便加深自己的印象。

# 前置準備 #

為了方便，這裡使用 sqlite 的 in-memory database，driver 使用的是 [go-sqlite3](https://github.com/mattn/go-sqlite3)。

安裝:

    go get github.com/mattn/go-sqlite3

測試用程式:

    package main

    import (
        "database/sql"
        _ "github.com/mattn/go-sqlite3"
        "log"
    )

    func main() {
        db := createTestDB()
        defer db.Close()

        // write your code here
    }

    func createTestDB() *sql.DB {
        db, err := sql.Open("sqlite3", ":memory:")
        if err != nil {
            log.Fatal(err)
        }

        _, err = db.Exec("CREATE TABLE foo (id INTEGER PRIMARY KEY ASC, name TEXT)")
        if err != nil {
            log.Fatal(err)
        }
        return db
    }


# 使用 Driver #

要使用 `database/sql` 裡的 API，一定得要搭配一套實作 `database/sql/driver` 的 driver，Go 內建並不支援任何資料庫，但官方有整理出來目前可使用的 [driver 清單](https://github.com/golang/go/wiki/SQLDrivers)。這些 driver 大都會在自己的 package 實作 `init function`，並在裡面將自己的 driver 註冊，所以使用者只需要 `import` 即可。

這次並不會使用 go-sqlite3 自己的 API；為了避免 Go Compiler 抱怨 package 沒在使用，需要加上 `blank identifier`。


    import (
        _ "github.com/mattn/go-sqlite3"
    )

# 建立 DB 物件 #

Go 操作資料庫的 API 都圍繞在 `DB` 這個物件上，除了 API 以外，它也會在內部管理著 Connection Pool，並且保證能安全地在多執行緒的程式內使用。常見的資料庫 API 不少是以一個連線為一個物件的概念來操作，可是 `DB` 一旦建立起來，就可以一直使用到程式結束為止再關閉，不需要每次使用時重新開啟與關閉。

建立的方式是透過 `sql.Open()`，輸入 driver 名字和 DSN 即可。

    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        log.Fatal(err)
    }
    // 操作 db...

# 執行 SQL #

執行如 `INSERT` 或 `UPDATE` 等不需要回傳查詢資料的 SQL，可以使用 `DB.Exec()` 這個 method:

    _, err = db.Exec("CREATE TABLE foo (id INTEGER PRIMARY KEY ASC, name TEXT)")
    if err != nil {
        log.Fatal(err)
    }

這個 method 支援 placeholder 語法，自動視需要跳脫字元，例如:

    result, err := db.Exec("INSERT INTO foo VALUES (NULL, ?)", "escape'me")
    if err != nil {
        log.Fatal(err)
    }

除了有錯誤時會回傳 `error` 以外，`DB.Exec()` 還會回傳 `Result` 這個物件。這個物件代表著 SQL 的執行結果，透過它可以知道剛剛執行 SQL 後所產生的 auto increment id，或者是受影響的資料筆數。

    id, _ := result.LastInsertId()
    log.Printf("ID: %d\n", id)  // "ID: 1"

# 查詢資料 #

需要查詢資料時，可以使用 `DB.Query()` 或 `DB.QueryRow()` 兩個 method。這兩個 method 的差別在於 `DB.Query()` 會把所有的結果傳回來，而 `DB.QueryRow()` 最多只會傳第一筆回來。和 `DB.Exec()` 相同，它們也都支援 placeholder 語法 :

    rows, err := db.Query("SELECT * FROM foo")
    // or
    row := db.QueryRow("SELECT * FROM foo WHERE id = ?", 1)

# 讀查詢出來的資料 #

`DB.Query()` 回傳的物件 `Rows` 代表著零至多筆的查詢結果，使用 `Rows.Scan()` 可以將第一行的資料寫入帶進去的參數指標內，接著再呼叫 `Rows.Next()` 就可以移至下一行:


    for rows.Next() {
        var id int
        var name string
        err = rows.Scan(&id, &name)
        if err != nil {
            log.Fatalf("Scan error: %q\n", err)
        }
        log.Printf("Query(): ID: %d, name %s", id, name)
    }

`DB.QueryRow()` 回傳的物件 `Row` 代表著零或一筆查詢結果，和 `Rows` 一樣，可以使用 `Row.Scan()` 把資料寫進指標內。

    var id int
    var name string
    row := db.QueryRow("SELECT * FROM foo WHERE id = ?", 1)
    err := row.Scan(&id, &name)
    if err != nil {
        log.Fatal(err)
    }
    log.Printf("QueryRow(): ID: %d, name %s", id, name)

# Prepared Statement #

Go 也有支援 Prepared Statement，使用 `DB.Prepare()` 就可以建立出 `Stmt` 物件

    stmt, err := db.Prepare("INSERT INTO foo VALUES (NULL, ?)")
    if err != nil {
        log.Fatal(err)
    }

Stmt 物件也提供了 `Stmt.Exec()`, `Stmt.Query()`, `Stmt.QueryRow()` 三個執行 SQL 的 API；和前面不同的是，只需要將 placeholder 的參數帶進去即可。

    for i := 0; i < 3; i++ {
        result, err := stmt.Exec("test" + string(i))
        if err != nil {
            log.Fatalf("Prepare error: %q", err)
        }
        id, _ := result.LastInsertId()
        log.Printf("Prepare insert ID: %d", id)
    }

# Transaction #

要使用資料庫 Transaction，就需要靠 `DB.Begin()` 這個 method 建立出 `Tx` 物件:

    tx, err := db.Begin()

透過同一個 `Tx` 物件所執行的動作，都會在同一個 Transaction 內。它提供和前面提過的 method 一樣的 API 來執行 SQL: `Tx.Exec()`, `Tx.Query()`, `Tx.QueryRow()`, `Tx.Prepare()`。

    result, err := tx.Exec("UPDATE foo SET name = 'abc'")
    if err != nil {
        tx.Rollback()
        log.Fatal(err)
    }
    count, _ := result.RowsAffected()
    log.Printf("Tx RowsAffected(): %d", count)
    tx.Commit()

當然免不了的要記得呼叫 `Tx.Commit()`, `Tx.Rollback()`來決定 Transaction 是否完成，一旦呼叫，這個 `Tx` 物件就不能再被用來執行 SQL，只能再重新開一個新 Transaction。

# 感想 #

`database/sql` 麻雀雖小，五臟俱全，現代資料庫操作會想要有的基本功能都支援了。除此之外，API 也十分簡潔一致；不同物件要執行 SQL 所用的 API signature 差異很小。上手快，不太需要一直查文件才會記得。

# Reference #

1. Package Sql http://golang.org/pkg/database/sql/
