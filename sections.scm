(define (e->s l)
  (map (cut number->string <>) l))

(define section-data (make-parameter (with-input-from-file "section.data.scm" (lambda () (eval (read))))))