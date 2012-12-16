(use zmq)

(include "lookup-port.scm")

(define get-ping-address-socket (make-socket 'req))
(connect-socket get-ping-address-socket (string-append "tcp://localhost:" lookup-port))
(send-message get-ping-address-socket "ping")

(define socket (make-socket 'rep))
(connect-socket socket (string-append "tcp://localhost:" (receive-message* get-ping-address-socket)))

(define (process)
  (receive-message* socket)
  (send-message socket "ping")
  (process))
(process)
