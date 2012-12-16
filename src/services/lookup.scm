(use zmq srfi-69)

(define the-get-destination-address "tcp://*:10000")
(define add-destination-address "tcp://*:10001")

(define destinations (make-hash-table))

(define (add-destination name address)
  (hash-table-set! destinations name address))

(define (get-destination-address name)
  (hash-table-ref destinations name))

(define add-destination-socket (make-socket 'rep))
(bind-socket add-destination-socket add-destination-address)

(define get-destination-socket (make-socket 'rep))
(bind-socket get-destination-socket the-get-destination-address)

;;; default destinations
; servers want these
(add-destination "mda-server" "4444")
(add-destination "mda-client" "4446")
(add-destination "log" "11000")
(add-destination "ping" "13000")

(define (process)
  (let ((msg (receive-message* get-destination-socket)))
    (print msg)
  (send-message get-destination-socket
                (get-destination-address msg)))
  (process))
(process)
