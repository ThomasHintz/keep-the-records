(use zmq posix)

; example useage
; csi -s router mda-client mda-server

(include "lookup-port.scm")

(define lookup-socket (make-socket 'req))
(connect-socket lookup-socket (string-append "tcp://localhost:" lookup-port))
(send-message lookup-socket (car (command-line-arguments)))
(define frontend (receive-message* lookup-socket))
(send-message lookup-socket (cadr (command-line-arguments)))
(define backend (receive-message* lookup-socket))

(process-wait (process-run (string-append "./a.out tcp://*:" frontend " tcp://*:" backend)))
