(use srfi-1)

(define section-data (make-parameter (eval (with-input-from-file "section.data.scm" (lambda () (read))))))

(define (list-club-levels club-level-lists)
  (map (lambda (club-level-list) (first club-level-list)) club-level-lists))

(define (list-books book-lists)
  (map (lambda (book-list) (first book-list)) book-lists))

(define (list-chapters chapter-lists)
  (map (lambda (chapter-list) (first chapter-list)) chapter-lists))

(define (select-club-level club-level-lists club-level)
  (second (first (filter (lambda (e) (string=? (first e) club-level)) club-level-lists))))

(define (select-book book-lists book)
  (second (first (filter (lambda (e) (string=? (first e) book)) book-lists))))