(use http-client uri-common intarweb json srfi-1 srfi-18)
(load "utils.scm")

(define *request-mutex* (make-mutex 'rest-request-mutex)) ; check note below
(define *api-user* (insert-file "send-grid-user"))
(define *api-key* (insert-file "send-grid-key"))

; there seems to be a bug in http-client that causes requests to fail if there is already a connection open. I can't/haven't figured out a way to close the requests connections without closing all http-client connections. So to keep requests working well I've shielded requests with a mutex and force http-client to close all connections after each request.

(define (rest-action url method parameters)
  (handle-exceptions ; see note above
   exn
   (begin (mutex-unlock! *request-mutex*)
          (abort exn))
   (let ((r (vector->list (with-input-from-request
                           (make-request method: method uri: (uri-reference url)) parameters json-read))))
     (close-all-connections!)
     (mutex-unlock! *request-mutex*)
     r)))

(define (send-mail #!key (subject #f) (text #f) (html #f) (from #f) (from-name #f) (to #f) (reply-to #f))
  (if (and subject (or text html) from from-name to reply-to)
      (rest-action "https://sendgrid.com/api/mail.send.json" 'POST
                   `((api_user . ,*api-user*)
                     (api_key . ,*api-key*)
                     (subject . ,subject)
                     (to . ,to)
                     (replyto . ,reply-to)
                     ,(if html `(html . ,html) `(text . ,text))
                     (from . ,from)
                     (fromname . ,from-name)))
      (abort "You must specify all keyword parameters!")))