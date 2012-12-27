; awana structure is the structure of clubs books and sections.
; the dsl can be used to easily parse this structure

(module awana-structure-dsl
  (
   awana-structure-lookup
  )
(import chicken scheme)
(use srfi-1 srfi-69)

; filters result of awana structure data based on specifics given as strings
; ex: (as-filter (as-filter "TnT" 'book) '("TnT" 'book)) equals (as-filter "TnT" 'book)
(define (as-filter data-l params)
  (if (> (length params) 0)
      (if (string? (first params))
	  (as-filter (second (first (filter (lambda (e) (string=? (first params) (first e))) data-l))) (cdr params))
	  data-l)
      data-l))

(define *mem-ht* (make-hash-table))

; the dsl function
; can be used like this:
;   ; load the structure data
;   (define section-data (make-parameter (include "src/sections/awana-structure.data.scm")))
;   ; look up the books for cubbies
;   (awana-stucture-lookup section-data "Cubbies" 'book)
;   ; returns: '("Hopper" "Jumper")
;   ; look up the chapters and sections for cubbies
;   (awana-struture-lookup section-data "Cubbies" "Hopper" 'chapter 'section)
(define (awana-structure-lookup section-data . rest)
  (if (hash-table-ref/default *mem-ht* rest #f)
      (hash-table-ref *mem-ht* rest)
      (let ((r (letrec ((ad-internal
			 (lambda (ol params)
			   (if (= (length params) 1)
			       (map (lambda (l)
				      (if (list? l)
					  (first l)
					  l))
				    (second ol))
			       (map (lambda (l)
				      `(,(first l)
					,(ad-internal l (cdr params))))
				    (second ol))))))
		 (as-filter (ad-internal section-data rest) rest))))
	(hash-table-set! *mem-ht* rest r)
	r)))
)
