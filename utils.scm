(use srfi-1)

(define (insert-file path)
  (with-input-from-file path (lambda () (read-string))))

(define (fold-sep proc sep start list)
  (let ((first #t))
    (fold (lambda (e o)
            (string-append o (if first (begin (set! first #f) "") sep) (proc e)))
          start
          list)))

(define (string-fold-sep proc sep list)
  (fold-sep proc sep "" list))

(define (range from/to . to)
  (let ((f (if (= (length to) 0) -1 (- from/to 1)))
        (t (if (> (length to) 0) (first to) from/to)))
    (do ((i (- t 1) (- i 1))
         (l '() (cons i l)))
        ((= i f) l))))