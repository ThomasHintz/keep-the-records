(use zmq)

(include "lookup-port.scm")

(define lookup (make-socket 'req))
(connect-socket lookup (string-append "tcp://localhost:" lookup-port))
(send-message lookup "log")

(define socket (make-socket 'sub))
(socket-option-set! socket 'subscribe "")
(bind-socket socket (string-append "tcp://*:" (receive-message* lookup)))

(define (process)
  (let ((msg (receive-message* socket)))
    (print msg))
  (process))
(process)
