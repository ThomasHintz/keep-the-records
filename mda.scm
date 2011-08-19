(require-extension srfi-1 srfi-13 srfi-18 srfi-69 tokyocabinet)

;;; utils

(define (dash->space s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\- c) " " (->string c)))) "" s))

(define (space->dash s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\space c) "-" (->string c)))) "" s))

(define (id->name id)
  (string-titlecase (dash->space id)))

(define (name->id name)
  (string-downcase (space->dash name)))

(define (list->path list)
  (fold (lambda (e o)
          (string-append o (db:sep) e))
        ""
        list))

;(define (db:open-db path)
;  (open-database path page-block-power: 14 dir-block-power: 14))

(define (db:open-db path)
  (tc-hdb-open path))

;;; setup tokyocabinet

;(define *db* (open-database "ktr-db" page-block-power: 14 dir-block-power: 14))
(define *db* "")
(define (db:db . val)
  (if (> (length val) 0)
      (set! *db* (first val))
      *db*))

(define *sep* "/")
(define (db:sep . val)
  (if (> (length val) 0)
      (set! *sep* (first val))
      *sep*))

(define db:list-index (make-parameter "the-list-index"))

(define *db-write-mutex* (make-mutex 'db-write-mutex))

;;; permissions

(define db:req-perms (make-parameter #t))
(define *perms-mutex* (make-mutex 'perms-mutex))
(define *perms* (make-hash-table))

(define (db:add-permission sid proc)
  (mutex-lock! *perms-mutex*)
  (hash-table-set! *perms* sid proc)
  (mutex-unlock! *perms-mutex*))

(define (db:allowed? sid path-list)
  (let ((v (hash-table-ref/default *perms* sid #f)))
    (and v (v path-list))))

(define (contains? l e)
  (not (eq? (filter (lambda (le) (string=? le e)) l) '())))

;;; macros

(define-syntax with-db
  (syntax-rules ()
    ((with-db path-list read-only body ...)
     (if #t
         (handle-exceptions
          exn
          (begin (mutex-unlock! *db-write-mutex*)
                 (abort exn))
          (begin (mutex-lock! *db-write-mutex*)
                 (let ((r body ...))
                   (mutex-unlock! *db-write-mutex*)
                   r)))
         (abort 'error)))))

(define-syntax db+
  (syntax-rules ()
    ((db+ amount first ...) (db:store (+ (db:read first ...) amount) first ...))))

(define-syntax db-
  (syntax-rules ()
    ((db- amount first ...) (db:store (- (db:read first ...) amount) first ...))))

;;; tokyocabinet db operations / to be refactored of course!

(define (tc-store db data path-list)
  (tc-hdb-put! db (name->id (list->path path-list)) (with-output-to-string (lambda () (write data)))))

(define (tc-read db path-list)
  (let ((val (tc-hdb-get db (name->id (list->path path-list)))))
    (if val
        (with-input-from-string val (lambda () (read)))
        'not-found)))

(define (tc-delete db path-list)
  (tc-hdb-delete! db (name->id (list->path path-list))))

(define (tc-exists? db path-list)
  (not (eq? (tc-read db path-list) 'not-found)))

;;; external funcs, they wrap db calls with permission and locking protection

(define (db:store data . path-list)
  (tc-store (db:db) data path-list))

(define (db:read . path-list)
  (tc-read (db:db) path-list))

(define (db:list-old . path-list)
  (let* ((s-form (list->path path-list))
	 (s-length (string-length s-form))
	 (list-length (length path-list)))
    (delete-duplicates (pair-fold (db:db)
				  (lambda (k v kvs)
				    (if (string= s-form k 0 s-length 0 (if (< (string-length k) s-length) 0 s-length))
					(cons (list-ref (string-split k (db:sep)) list-length) kvs)
					kvs))
				  '())
		       string=)))

(define (db:update-list data . path-list)
  (let* ((p (append path-list `(,(db:list-index))))
	 (l (tc-read (db:db) p))
	 (ls (if (eq? l 'not-found) '() l)))
    (or (contains? ls data) (tc-store (db:db) (cons data ls) p))))

(define (db:list . path-list)
  (let ((r (tc-read (db:db) (append path-list `(,(db:list-index))))))
    (if (eq? r 'not-found)
	'()
	r)))

(define (db:delete . path-list)
  (tc-delete (db:db) path-list))

(define (db:delete-r . path-list)
  (let* ((s-form (list->path path-list))
	 (s-length (string-length s-form))
	 (list-length (length path-list)))
    (map (lambda (k) (delete! (db:db) k))
	 (pair-fold (db:db)
		    (lambda (k v kvs)
		      (if (string= s-form k 0 s-length 0 (if (< (string-length k) s-length) 0 s-length))
			  (cons k kvs)
			  kvs))
		    '()))))