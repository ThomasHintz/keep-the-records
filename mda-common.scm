(define (serialize l) (with-output-to-string (lambda () (write l))))
(define (deserialize s) (with-input-from-string s (lambda () (read))))

