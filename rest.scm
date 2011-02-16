(use http-client uri-common intarweb json srfi-1 srfi-18)
(load "utils.scm")

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


;(use base64 sha1)
;(load "../hmac/hmac.scm")

;(define secret-access-key (make-parameter ""))

;(define (make-aws-authorization verb resource #!key (date #f) (amz-headers '()) (content-md5 #f) (content-type #f))
;  (let* ((can-amz-headers (sort (map (lambda (header)
;                                       `(,(string-downcase (car header)) . ,(cdr header)))
;                                     amz-headers)
;                                (lambda (v1 v2)
;                                  (string<? (car v1) (car v2)))))
;         (can-string (with-output-to-string
;                       (lambda ()
;                         (display (string-upcase verb))
;                         (newline)
;                         (if content-md5 (display content-md5) (display ""))
;                         (newline)
;                         (if content-type (display content-type) (display ""))
;                         (newline)
;                         (if date (display date) (display ""))
;                         (newline)
;                         (display (fold (lambda (e o)
;                                        (string-append o (sprintf "~a:~a~%" (car e) (cdr e))))
;                                      ""
;                                      can-amz-headers))
;                         (display resource))))
;         (hmac-sha1 (base64-encode ((sha1-hmac (secret-access-key)) can-string))))
;    (values hmac-sha1 can-string)))


;(secret-access-key "")
;(define sig (make-aws-authorization "GET" "/test-bucket-keep-the-records/test-ktr" date: "1297806701"))

;(define (get-test)
;  (handle-exceptions
;   exn
;   ((condition-property-accessor 'client-error 'body) exn)
;   (with-input-from-request
;    (make-request method: 'GET
;                  uri: (uri-reference "http://s3.amazonaws.com/test-bucket-keep-the-records/test-ktr"))
;    `((AWSAccessKeyId . "AKIAJ4BAYHGF254QF7DQ")
;      (Expires . "1297806701")
;      (Signature . ,sig))
;    json-read)))