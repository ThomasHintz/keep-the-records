;;; utilities
(use srfi-19 http-session spiffy-cookies http-session spiffy-cookies)

(define (todays-date)
  (date->string (current-date) "~Y/~m/~d"))

(define (store? test)
  (if (> (length test) 0) #t #f))

;;; macros

(define-syntax neq?
  (syntax-rules ()
    ((neq? e1 e2)
     (not (eq? e1 e2)))))

(define-syntax with-default
  (syntax-rules ()
    ((with-default expr default)
     (let ((e expr))
       (if (eq? e 'not-found)
           default
           e)))))

;(define-syntax define-db-func
;  (syntax-rules ()
;    ((define-db-func opts (procs ...))
;     (define (prop opts . prop)
;       (if (store? prop)
;           (db-store (car prop) "nepco" procs ...)
;           (db:read "nepco" procs ...))))))

(define-syntax db-user
  (syntax-rules ()
    ((db-user prop file default)
     (define (prop user . prop)
       (if (store? prop)
           (db:store (car prop) "users" user file)
           (with-default (db:read "users" user file) default))))))

(define-syntax db-club
  (syntax-rules ()
    ((db-club prop file default)
     (define (prop club . prop)
       (if (store? prop)
           (db:store (car prop) "clubs" club file)
           (with-default (db:read "clubs" club file) default))))))

(define-syntax db-club-auth
  (syntax-rules ()
    ((db-club-auth prop file default)
     (define (prop club url . email)
       (if (store? email)
           (db:store (car email) "clubs" club "auth-urls" url file)
           (with-default (db:read "clubs" club "auth-urls" url file) default))))))

(define-syntax db-club-clubber
  (syntax-rules ()
    ((db-club-clubber prop file default)
     (define (prop club name . prop)
       (if (store? prop)
           (db:store (car prop) "clubs" club "clubbers" name file)
           (with-default (db:read  "clubs" club "clubbers" name file) default))))))

(define-syntax db-club-clubber-date
  (syntax-rules ()
    ((db-club-clubber-date prop file default . no-update-points)
     (define (prop club mem date . prop-v)
       (if (store? prop-v)
           (begin (update-points (lambda (c n d) (prop c n d)) (car prop-v) club mem date)
                  (let ((d-l (string-split date (db:sep))))
                  (db:update-list (first d-l) "clubs" club "clubbers" mem "attendance")
                  (db:update-list (second d-l) "clubs" club "clubbers" mem "attendance" (first d-l))
                  (db:update-list (third d-l) "clubs" club "clubbers" mem "attendance" (first d-l) (second d-l))
                  (db:update-list file "clubs" club "clubbers" mem "attendance" date)
                  (db:store (car prop-v) "clubs" club "clubbers" mem "attendance" date file)))
           (with-default (db:read "clubs" club "clubbers" mem "attendance" date file) default))))))

(define-syntax db-club-clubber-section
  (syntax-rules ()
    ((db-club-clubber-section prop default)
     (define (prop club mem book chapter section . prop)
       (if (store? prop)
           (db:store (car prop) "clubs" club "clubbers" mem "sections" "books" book "chapters" chapter section)
           (with-default (db:read "clubs" club "clubbers" mem "sections" "books" book "chapters" chapter section)
                         default))))))

(define-syntax db-club-par
  (syntax-rules ()
    ((db-club-par prop file default)
     (define (prop club parent . prop)
       (if (store? prop)
           (db:store (car prop) "clubs" club "parents" parent file)
           (with-default (db:read "clubs" club "parents" parent file) default))))))

;;; clubber funcs

(define (update-points func new-val club name date)
  (cond ((and (func club name date) (not new-val))
         ;(day-points club name date (- (day-points club name date) 1))
         (total-points club name (- (total-points club name) 1)))
        ((and (not (func club name date)) new-val)
         ;(day-points club name date (+ (day-points club name date) 1))
         (total-points club name (+ (total-points club name) 1)))))

(define (secondary-parent club name . parent)
  (if (store? parent)
      (db:store (car parent) "clubs" club "parents" (primary-parent name) "spouse-name")
      (with-default (db:read "clubs" club "parents" (primary-parent name) "spouse-name") "")))

;(define (day-points club name date . points)
;  (if (store? points)
;      (db:store (car points) "clubs" club "clubbers" name "attendance" date "day-points")
;      (with-default (db:read "clubs" club "clubbers" name "attendance" date "day-points") 0)))

;;; database functions

; (user-name user . name)
(db-user user-name "name" 'not-found)
(db-user user-club "club" 'not-found)
(db-user user-email "email" 'not-found)
(db-user user-phone "phone" "")
(db-user user-birthday "birthday" "")
(db-user user-address "address" "")
(db-user user-pw "pw" 'not-found)

; (club-address club . address)
(db-club club-name "name" 'not-found)
(db-club club-users "club-users" '())

; (auth-url club url . email)
(db-club-auth auth-url "email" #f)

; (grade club clubber-name . grade)
(db-club-clubber name "name" 'not-found)
(db-club-clubber grade "grade" "")
(db-club-clubber birthday "birthday" "")
(db-club-clubber club-level "club-level" "")
(db-club-clubber notes "notes" "")
(db-club-clubber allergies "allergies" "")
(db-club-clubber primary-parent "primary-parent" "")
(db-club-clubber total-points "total-points" 0)
(db-club-clubber book "book" 0)
(db-club-clubber last-section "last-section" '(1 0))
(db-club-clubber date-registered "date-registered" "09/01/10") ; mm/dd/yy
(db-club-clubber thank-you "thank-you" #f)

; (present club clubber-name date . present)
(db-club-clubber-date present "present" #f)
(db-club-clubber-date bible "bible" #f)
(db-club-clubber-date handbook "handbook" #f)
(db-club-clubber-date uniform "uniform" #f)
(db-club-clubber-date friend "friend" #f)
(db-club-clubber-date extra "extra" #f)

; (clubber-section club clubber book chapter section . date)
(db-club-clubber-section clubber-section #f)

; (parent-spouse club spouse-name . spouse-name)
(db-club-par parent-name "name" "")
(db-club-par parent-spouse "spouse" "")
(db-club-par parent-email "email" "")
(db-club-par parent-phone-1 "phone-1" "")
(db-club-par parent-phone-2 "phone-2" "")
(db-club-par parent-address "address" "")
(db-club-par parent-release-to "release-to" "")
(db-club-par parent-children "children" '())