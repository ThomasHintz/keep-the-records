(load "src/utils/misc-utils")
(import misc-utils)

(define (e->s l)
  (map (cut number->string <>) l))

(define (srange from/to . to)
  (e->s
   (if (empty? to)
       (range from/to)
       (range from/to (car to)))))

(define section-data (make-parameter (include "section.data.scm")))
