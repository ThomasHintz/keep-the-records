(module sections
  (
   ;;; procs
   ad
  )
(import chicken scheme)
(load "src/utils/misc-utils")
(import misc-utils)
(load "src/sections/awana-structure-dsl.scm")
(import awana-structure-dsl)

(define (e->s l)
  (map (cut number->string <>) l))

(define (srange from/to . to)
  (e->s
   (if (empty? to)
       (range from/to)
       (range from/to (car to)))))

(define section-data (make-parameter (include "src/sections/awana-structure.data.scm")))

;;; awana-structure lookup using dsl, see awana-data-dsl.scm
(define (ad . r)
  (apply awana-structure-lookup (section-data) r))

)
