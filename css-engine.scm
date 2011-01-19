(require-extension spiffy intarweb srfi-69)

;;; css resource handler

(define *css-resources* (make-hash-table equal?))
(define css-headers (lambda (res) `((content-type text/css) (content-length ,(string-length res)))))

(define (register-css-dispatcher)
  (handle-not-found
   (let ((old-handler (handle-not-found)))
     (lambda (path)
       (let ((proc (css-resource-ref path)))
         (if proc
             (run-css-resource proc)
             (old-handler path)))))))

(register-css-dispatcher)

(define (add-css-resource! path proc)
  (hash-table-set! *css-resources* path proc))

(define (css-resource-ref path)
  (hash-table-ref/default *css-resources* path #f))

(define (run-css-resource proc)
  (let ((res (proc)))
    (with-headers (css-headers)
                  (lambda ()
                    (write-logged-response)
                    (request-method (current-request))
                    (display res (response-port (current-response)))))))

(define (define-css path proc)
  (add-css-resource! path proc))