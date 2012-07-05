(use srfi-1)

(define-syntax fold*
  (syntax-rules ()
    ((fold* proc s l)
     (letrec ((loop (lambda (rl o)
                      (if (eq? rl '())
                          o
                          (loop (cdr rl) (apply proc (append (car rl) (list o))))))))
       (loop l s)))))

(define-syntax folds*
  (syntax-rules ()
    ((folds* proc l)
     (letrec ((loop (lambda (rl o)
                      (if (eq? rl '())
                          o
                          (string-append o (loop (cdr rl) (apply proc (car rl))))))))
       (loop l "")))))

(define-syntax neq?
  (syntax-rules ()
    ((neq? e1 e2)
     (not (eq? e1 e2)))))
