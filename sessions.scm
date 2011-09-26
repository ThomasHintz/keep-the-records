(use http-session)

(define (session-item->list session-item)
  (list (session-item-expiration session-item)
	(session-item-ip session-item)
	(session-item-bindings session-item)
	(session-item-finalizer session-item)))

(define (list->session-item l)
  (apply make-session-item l))

(session-storage-set!
 (lambda (sid session-item)
   (db:store (session-item->list session-item) "sessions" sid)))

(session-storage-ref
 (lambda (sid)
  (let ((r (db:read "sessions" sid)))
    (if (equal? r 'not-found)
	#f
	(list->session-item r)))))

(session-storage-delete!
 (lambda (sid)
   (db:delete "sessions" sid)))