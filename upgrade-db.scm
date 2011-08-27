(use tokyocabinet sdbm)

(define sdbm-db (open-database "ktr-db-convert-from" page-block-power: 14 dir-block-power: 14))
(define tc-db (tc-hdb-open "ktr-db-convert-to"))

(pair-fold sdbm-db (lambda (k v kvs)
		     (tc-hdb-put! tc-db k v)) '())
