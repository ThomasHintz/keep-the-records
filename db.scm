(require-extension posix srfi-1 srfi-13)

(define (dash->space s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\- c) " " (->string c)))) "" s))

(define (space->dash s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\space c) "-" (->string c)))) "" s))

(define (id->name id)
  (string-titlecase (dash->space id)))

(define (name->id name)
  (string-downcase (space->dash name)))

(define prefix-path (make-parameter #f))

(define (list->path list)
  (name->id (if (> (length list) 1)
                (string-append (list-ref list 0)
                               (fold (lambda (e o)
                                       (string-append o "/" e))
                                     ""
                                     (drop list 1)))
                (list-ref list 0))))

(define (db-store data . path-list)
  (when (and (> (length path-list) 1)
             (not (directory-exists? (list->path (take path-list (- (length path-list) 1))))))
    (create-directory (list->path (take path-list (- (length path-list) 1))) #t))
  (with-output-to-file (list->path path-list)
    (lambda ()
      (write data))))

(define (db-read . path-list)
  (if (file-exists? (list->path path-list))
      (with-input-from-file (list->path path-list)
        (lambda ()
          (read)))
      'not-found))

(define (db-list . path-list)
  (let ((path (list->path path-list)))
    (if (directory? path)
        (directory path)
        '())))

(define-syntax db+
  (syntax-rules ()
    ((db+ amount first ...) (db-store (+ (db-read first ...) amount) first ...))))

(define-syntax db-
  (syntax-rules ()
    ((db- amount first ...) (db-store (- (db-read first ...) amount) first ...))))