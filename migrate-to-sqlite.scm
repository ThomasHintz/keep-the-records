(use tokyocabinet sqdb)

(define tc-db (tc-hdb-open "ktr-db"))
(define sq-db (open-database "sqlite-db"))

(set-busy-timeout! sq-db 1000)

(tc-hdb-fold
 tc-db
 (lambda (k v o)
   (store sq-db k v)
   "")
 "")

(close-database sq-db)
(tc-hdb-close tc-db)
