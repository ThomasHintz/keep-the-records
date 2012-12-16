(use zmq)

(include "lookup-port.scm")

(define lookup-socket (make-socket 'req))
(connect-socket lookup-socket (string-append "tcp://*:" lookup-port))
(send-message lookup-socket (car (command-line-arguments)))
(define socket (make-socket 'req))
(connect-socket socket (string-append "tcp://localhost:" (receive-message* lookup-socket)))
(send-message socket (cadr (command-line-arguments)))
(print (receive-message* socket))
