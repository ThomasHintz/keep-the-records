(use zmq)

(include "mda-common.scm")

(define retries (make-parameter 10))
(define timeout (make-parameter (* 1000 100))) ; 10ms

(define socket #f)

(define (setup-socket)
  (set! socket (make-socket 'req))
  (connect-socket socket "tcp://localhost:4444"))
(setup-socket)

(define (reconnect)
  (close-socket socket)
  (setup-socket))

(define (do-op op)
  (send-message socket (serialize op))
  (letrec ((poll-loop
	    (lambda (timeout retries max-retries)
	      (if (>= retries max-retries)
		  (abort 'db-connection-timeout)
		  (let ((pi `(,(make-poll-item socket in: #t))))
		    (if (= 0 (poll pi timeout))
			(begin (reconnect)
			       (poll-loop timeout (+ retries 1) max-retries))
			(let ((response (deserialize (receive-message* socket))))
			  (if (eq? (car response) 'success)
			      (cadr response)
			      (begin (print response) (abort (cdr response)))))))))))
	   (poll-loop (timeout) 0 (retries))))

(define db:sep (make-parameter "/"))

(define (db:store v . k)
  (do-op `(put ,(serialize v) ,@k)))

(define (put-async v . k) 'not-implemented)

(define (db:read . k)
  (do-op `(get ,@k)))

(define (db:list . k)
  (do-op `(db-list ,@k)))

(define (db:update-list v . k)
  (do-op `(update-list ,v ,@k)))

(define (db:delete . k)
  (do-op `(delete ,@k)))
