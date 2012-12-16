(require-extension spiffy intarweb srfi-69 uri-common awful)

;;; pdf resource handler

(define *pdf-resources* (make-hash-table equal?))
(define pdf-headers (lambda (res) `((content-type application/pdf) (content-length ,(string-length res)))))

(define (register-pdf-dispatcher)
  (handle-not-found
   (let ((old-handler (handle-not-found)))
     (lambda (_)
       (let* ((path-list (uri-path (request-uri (current-request))))
              (path (if (null? (cdr path-list))
                        (car path-list)
                        (++ "/" (concat (cdr path-list) "/")))))
       (let ((proc (pdf-resource-ref path)))
         (if proc
             (run-pdf-resource proc)
             (old-handler _))))))))

(register-pdf-dispatcher)

(define (add-pdf-resource! path proc)
  (hash-table-set! *pdf-resources* path proc))

(define (pdf-resource-ref path)
  (hash-table-ref/default *pdf-resources* path #f))

(define (run-pdf-resource proc)
  (let ((res (proc)))
    (with-headers (pdf-headers res)
                  (lambda ()
                    (write-logged-response)
                    (request-method (current-request))
                    (display res (response-port (current-response)))))))

(define (define-pdf path proc)
  (add-pdf-resource! path proc))
