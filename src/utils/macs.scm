(module macs
  (
   make-global-parameter fold* folds* neq?
  )
(import chicken scheme)
(use srfi-1)

; fold and return as string
; (fold* (lambda (id, group) (string-append (name group id) (<br>))) ""
; '(('group1 "123") ('group2 "456")))

(define-syntax make-global-parameter
  (syntax-rules ()
    ((_ default)
     (let ((internal-val default))
       (lambda (#!rest new-val)
         (if (null? new-val)
             internal-val
             (set! internal-val new-val)))))))

(define-syntax fold*
  (syntax-rules ()
    ((fold* proc s l)
     (letrec ((loop (lambda (rl o)
                      (if (eq? rl '())
                          o
                          (loop (cdr rl) (apply proc (append (car rl) (list o))))))))
       (loop l s)))))

; same as fold*, but can handle multiple lists

(define-syntax folds*
  (syntax-rules ()
    ((folds* proc l)
     (letrec ((loop (lambda (rl o)
                      (if (eq? rl '())
                          o
                          (string-append o (loop (cdr rl) (apply proc (car rl))))))))
       (loop l "")))))
; not equal

(define-syntax neq?
  (syntax-rules ()
    ((neq? e1 e2)
     (not (eq? e1 e2)))))

)
