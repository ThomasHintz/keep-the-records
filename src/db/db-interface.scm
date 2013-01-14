; author: Thomas Hintz
; email: t@thintz.com
; license: bsd

; Copyright (c) 2012-2013, Thomas Hintz
; All rights reserved.

; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;     * Redistributions of source code must retain the above copyright
;       notice, this list of conditions and the following disclaimer.
;     * Redistributions in binary form must reproduce the above copyright
;       notice, this list of conditions and the following disclaimer in the
;       documentation and/or other materials provided with the distribution.
;     * Neither the name of the author nor the
;       names of its contributors may be used to endorse or promote products
;       derived from this software without specific prior written permission.

; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THOMAS HINTZ BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; 	    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; 	    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; 	    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; 	    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(module db-interface
  (;; params
   db:sep db:path db:flags

   ;; procs
   db:store db:read db:list db:update-list db:remove-from-list db:delete
   db:pause db:resume db:connect db:disconnect

   ;; constants
   db:flag-no-lock db:flag-writer db:flag-reader db:flag-create
   )

(import scheme chicken ports srfi-13 data-structures)
(use tokyocabinet srfi-1 srfi-13 srfi-18)
(load "src/utils/macs") (import macs)
(load "src/utils/threading-extras") (import threading-extras)

;;; constants
(define db:flag-no-lock TC_HDBONOLCK)
(define db:flag-writer TC_HDBOWRITER)
(define db:flag-reader TC_HDBOREADER)
(define db:flag-create TC_HDBOCREAT)

;;; params
(define db:sep (make-global-parameter "/"))
(define db:path (make-global-parameter 'undefined))
(define db:flags (make-global-parameter
                  (fx+ TC_HDBONOLCK (fx+ TC_HDBOWRITER (fx+ TC_HDBOREADER TC_HDBOCREAT)))))

(define db (make-parameter 'undefined))

; all keys that start with this are for indexes
; to keep indexes from clashing with db data
(define list-index-prefix (make-global-parameter "the-list-index"))

(define (contains? l e)
  (not (eq? (filter (lambda (le) (equal? le e)) l) '())))

(define (dash->space s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\- c) " " (->string c)))) "" s))

(define (space->dash s)
  (string-fold (lambda (c o) (string-append o (if (char=? #\space c) "-" (->string c)))) "" s))

(define (id->name id)
  (string-titlecase (dash->space id)))

(define (name->id name)
  (string-downcase (space->dash name)))

(define (list->path list)
  (fold (lambda (e o)
          (string-append o (db:sep) e))
        ""
        list))

(define *active-db-queries* (make-mutex/value 'active-db-queries 0))
(define *paused* (make-mutex/value 'paused #f))
(define *resume* (make-condition-variable 'resume))
(define *query-finished* (make-condition-variable 'query-finished))

(define-syntax with-db
  (syntax-rules ()
    ((_ f ...)
     (begin
       (mutex-wait! *paused* (lambda (paused) (eq? paused #f)) *resume*)
       (mutex-update! *active-db-queries* add1)
       (let ((r (begin f ...)))
         (mutex-update! *active-db-queries* sub1)
         (condition-variable-signal! *query-finished*)
         r)))))

;;; db funcs

(define (db:store data . path-list)
  (with-db
   (let ((k (name->id (list->path path-list)))
         (v (with-output-to-string (lambda () (write data)))))
     (tc-hdb-put! (db) k v) #t)))

(define (db:read . path-list)
  (with-db
   (let ((val (tc-hdb-get (db) (name->id (list->path path-list)))))
     (if val
         (with-input-from-string val (lambda () (read)))
         'not-found))))

(define (db:list . path-list)
  (with-db
   (let ((r (apply db:read (append path-list `(,(list-index-prefix))))))
     (if (eq? r 'not-found)
         '()
         r))))

(define (db:update-list data . path-list)
  (with-db
   (let* ((p (append path-list `(,(list-index-prefix))))
          (l (apply db:read p))
          (ls (if (eq? l 'not-found) '() l)))
     (or (contains? ls data) (apply db:store (cons data ls) p)))))

(define (db:remove-from-list data . path-list)
  (with-db
   (let* ((p (append path-list `(,(list-index-prefix))))
	 (l (apply db:read p))
	 (ls (if (eq? l 'not-found) '() l)))
    (apply db:store
           (filter (lambda (e)
                     (not (equal? e data)))
                   ls)
           p))))

(define (db:delete . path-list)
  (with-db
   (let ((k (name->id (list->path path-list))))
     (tc-hdb-delete! (db) k))))

(define (db:pause)
  (if (equal? (mutex-specific *paused*) #f)
      (begin
        (mutex-update! *paused* #t)
        (mutex-wait! *active-db-queries*
                     (lambda (num-queries) (= num-queries 0))
                     *query-finished*)
        (db:disconnect)
        #t)
      'already-paused!))

(define (db:resume)
  (if (equal? (mutex-specific *paused*) #t)
      (begin
        (db:connect)
        (mutex-update! *paused* #f)
        (condition-variable-signal! *resume*)
        #t)
      'not-paused!))

(define (db:connect)
  (db (tc-hdb-open (db:path) flags: (db:flags))))

(define (db:disconnect)
  (tc-hdb-close (db))
  (db 'undefined))

)
