(use http-client uri-common intarweb json srfi-1 srfi-18)
(load "utils")

(define *api-user* (insert-file "send-grid-user"))
(define *api-key* (insert-file "send-grid-key"))

(define (rest-action url method parameters)
  (vector->list (with-input-from-request
                 (make-request method: method uri: (uri-reference url)) parameters json-read)))

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
