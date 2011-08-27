(use srfi-1 srfi-13 srfi-18 srfi-69 tokyocabinet mailbox (prefix amazon-s3 amazon-s3:))

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

;;; amazon-s3 stuff

(load "aws-setup.scm") ; for credentials
(define as3-bucket (make-parameter (if (is-production?) "keep-the-records-backup-db" "keep-the-records-dev-backup-db")))

(define (make-as3-thread mb)
  (make-thread
   (lambda ()
     (let loop ()
       (let ((k-v (mailbox-receive! mb)))
	 (if (eq? (first k-v) 'put!)
	     (amazon-s3:put-string! (as3-bucket) (second k-v) (third k-v))
	     (amazon-s3:delete-object! (as3-bucket) (second k-v))))
       (loop)))))

(define as3-mailbox (make-parameter (make-mailbox)))

; make amazon s3 threads
(for-each (lambda (n) (thread-start! (make-as3-thread (as3-mailbox)))) (range 20))

(define (as3-put! k v)
  (mailbox-send! (as3-mailbox) `(put! ,k ,v)))

(define (as3-delete! k v)
  (mailbox-send! (as3-mailbox) `(delete! ,k ,v)))

;;; tokyocabinet db operations / to be refactored of course!

(define (tc-store db data path-list)
  (let ((k (name->id (list->path path-list)))
	(v (with-output-to-string (lambda () (write data)))))
    (tc-hdb-put! db k v)
    (as3-put! k v)))

(define (tc-read db path-list)
  (let ((val (tc-hdb-get db (name->id (list->path path-list)))))
    (if val
        (with-input-from-string val (lambda () (read)))
        'not-found)))

(define (tc-delete db path-list)
  (let ((k (name->id (list->path path-list))))
    (tc-hdb-delete! db k)
    (as3-delete! k)))

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