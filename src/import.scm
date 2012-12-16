(use csv typeclass input-classes abnf srfi-13)

(load "utils.scm")
(load "mda.scm")
(load "storage-funcs.scm")

;;; csv setup

(define char-list-<Input>
  (make-<Input> null? car cdr))

(define char-list-<Token>
  (Input->Token char-list-<Input>))

(define char-list-<CharLex>
  (Token->CharLex char-list-<Token>))

(define char-list-<CoreABNF>
  (Token.CharLex->CoreABNF char-list-<Token> 
			   char-list-<CharLex>))

(define char-list-<CSV>
  (CoreABNF->CSV char-list-<CoreABNF> ))

(define parse-csv ((make-parser char-list-<CSV>) #\|))

;;; import stuff

(define (data-list file)
  (map (lambda (rec) (csv-record->list rec)) (parse-csv (insert-file file))))

(define (import-row row club cl g)
  (print row) (newline)
  (let* ((name-raw (string-split (first row) " "))
         (n (string-append (second name-raw) " " (first name-raw)))
         (parents-raw (string-split (fourth row)))
         (p1 (string-append (first parents-raw) " " (second parents-raw)))
         (p2 (if (> (length parents-raw) 2) (string-append (third parents-raw) " " (fourth parents-raw)) #f)))
    ;(print n) (newline)
    (name club n n)
    (grade club n g)
    (birthday club n (second row))
    (club-level club n cl)
    (allergies club n (third row))
    (primary-parent club n p1)
    (parent-name club p1 p1)
    (when p2 (parent-spouse club p1 p2))
    (parent-email club p1 (seventh row))
    (parent-phone-1 club p1 (fifth row))
    (parent-phone-2 club p1 (sixth row))
    (parent-address club p1 (eighth row))
    (when (> (length row) 8) (parent-release-to club p1 (ninth row)))
    (parent-children club p1 (let ((children (parent-children club p1)))
                          (if (eq? children 'not-found)
                              `(,n)
                              (cons n children))))))

(define (restore-commas row)
  (map (lambda (e) (string-map (lambda (c) (if (char=? c #\@) #\, c)) e)) row))

(define (fill-spaces row)
  (string-map (lambda (c) (if (char=? c #\space) #\~ c)) row))

(define (restore-spaces row-list)
  (map (lambda (e) (string-map (lambda (c) (if (char=? c #\~) #\space c)) e)) row-list))

(define (setup-db)
  (db:db (db:open-db "ktr-db")))
(setup-db)

(define (import-file file club club-level grade)
  (map (lambda (row)
         (import-row (restore-commas (restore-spaces (string-split (fill-spaces (first row)) "," #t)))
                     club club-level grade))
         ;(restore-commas (restore-spaces (string-split (fill-spaces (first row)) "," #t))))
       (data-list file)))