(use zmq posix)

(include "lookup-port.scm")

(define lookup (make-socket 'req))
(connect-socket lookup (string-append "tcp://localhost:" lookup-port))
(send-message lookup "log")

(define socket (make-socket 'sub))
(socket-option-set! socket 'subscribe "")
(bind-socket socket (string-append "tcp://*:" (receive-message* lookup)))

(define (process)
  (let ((msg (receive-message* socket)))
    (with-output-to-file "the-log" (lambda () (print "[" (seconds->string (- (current-seconds) (* 7 60 60))) "] " msg)) append:))
  (process))
(process)
