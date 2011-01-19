(require-extension srfi-1 srfi-13 srfi-18 sdbm)

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
          (string-append o "/" e))
        ""
        list))

(define *db-write-mutex* (make-mutex 'db-write-mutex))

;;; setup sdbm

(define *db* (open-database "ktr-db" page-block-power: 14 dir-block-power: 14))

;;; permissions

(define req-perms (make-parameter #t))
(define *perms* '())

(define (db-add-permission id-proc test-proc)
  (set! *perms* (cons `(,id-proc ,test-proc) *perms*)))

(define (db-allowed? path-list exists read-only)
  (fold (lambda (perm o)
          (if o
              o
              (if ((first perm) path-list)
                  ((second perm) path-list exists read-only)
                  #f)))
        #f
        *perms*))

;;; macros

(define-syntax with-db
  (syntax-rules ()
    ((with-db path-list read-only body ...)
     (if (or (not (req-perms)) (and (req-perms) (db-allowed? path-list (sdbm-exists? *db* path-list) read-only)))
         (begin (mutex-lock! *db-write-mutex*)
                (let ((r body ...))
                  (mutex-unlock! *db-write-mutex*)
                  r))
         (abort 'permission-denied)))))

(define-syntax db+
  (syntax-rules ()
    ((db+ amount first ...) (db-store (+ (db-read first ...) amount) first ...))))

(define-syntax db-
  (syntax-rules ()
    ((db- amount first ...) (db-store (- (db-read first ...) amount) first ...))))

;;; db operations
;;; only store, read, list, exists?, and delete

(define (sdbm-store db data path-list)
  (store! db (name->id (list->path path-list)) (with-output-to-string (lambda () (write data)))))

(define (sdbm-read db path-list)
  (let ((val (fetch db (name->id (list->path path-list)))))
    (if val
        (with-input-from-string val (lambda () (read)))
        'not-found)))

(define (sdbm-delete db path-list)
  (delete! db (name->id (list->path path-list))))

(define (sdbm-exists? db path-list)
  (not (eq? (sdbm-read db path-list) 'not-found)))

;;; external funcs, they wrap db calls with permission and locking protection

(define (db-store data . path-list)
  (with-db path-list #f (sdbm-store *db* data path-list)))

(define (db-read . path-list)
  (with-db path-list #t (sdbm-read *db* path-list)))

(define (db-list . path-list)
  (with-db
   path-list #t
   (let* ((s-form (list->path path-list))
          (s-length (string-length s-form))
          (list-length (length path-list)))
     (delete-duplicates (pair-fold *db*
                                   (lambda (k v kvs)
                                     (if (string= s-form k 0 s-length 0 (if (< (string-length k) s-length) 0 s-length))
                                         (cons (list-ref (string-split k "/") list-length) kvs)
                                         kvs))
                                   '())
                        string=))))

(define (db-delete . path-list)
  (with-db path-list #f (sdbm-delete *db* path-list)))

(define (db-delete-r . path-list)
  (with-db path-list #f
           (let* ((s-form (list->path path-list))
                  (s-length (string-length s-form))
                  (list-length (length path-list)))
             (map (lambda (k) (delete! *db* k))
                  (pair-fold *db*
                             (lambda (k v kvs)
                               (if (string= s-form k 0 s-length 0 (if (< (string-length k) s-length) 0 s-length))
                                   (cons k kvs)
                                   kvs))
                             '())))))