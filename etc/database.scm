(db:path "ktr-db")
(db:flags (fx+ db:flag-no-lock (fx+ db:flag-writer (fx+ db:flag-reader db:flag-create))))
