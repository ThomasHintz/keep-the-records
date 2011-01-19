(define (insert-file path)
  (with-input-from-file path (lambda () (read-string))))

(require-extension intarweb http-client uri-common)
(define (get-code uri)
  (let-values (((h u r) (call-with-input-request uri #f (lambda (p) #f))))
    (response-code r)))

(define (fold-sep proc sep start list)
  (let ((first #t))
    (fold (lambda (e o)
            (string-append o (if first (begin (set! first #f) "") sep) (proc e)))
          start
          list)))

(define (string-fold-sep proc sep list)
  (fold-sep proc sep "" list))