(use srfi-13)

(load "src/utils/macs") (import macs)
(load "src/db/db-interface") (import db-interface)
;; (load "src/utils/misc-utils") (import misc-utils)
(load "storage-funcs")
;; (load "demo-data")
;; (load "handlers")
;; (load "pdf")
;; (load "src/sections/sections") (import sections)
;; (load "rest")
;; (load "sessions")
;; (load "src/utils/date-time-utils") (import date-time-utils)

(include "etc/database.scm")
(db:connect)

(define m-church "monterey-baptist-church0")
(define s-church "steamboat-rock-baptist-church0")



(define ++ string-append)

(define clubber-items
  `(("name" ,name) ("grade" ,grade) ("birthday" ,birthday)
    ("club" ,club-level) ("notes" ,notes) ("allergies" ,allergies)
    ("primary parent" ,primary-parent) ("points" ,total-points)
    ("date registered" ,date-registered)))

(define parent-items
  `(("name" ,parent-name) ("spouse" ,parent-spouse)
    ("email" ,parent-email) ("phone 1" ,parent-phone-1)
    ("phone 2" ,parent-phone-2) ("address" ,parent-address)
    ("release to" ,parent-release-to)))

(define clubber-date-items
  `(("present" ,present) ("bible" ,bible) ("handbook" ,handbook) ("uniform" ,uniform)
    ("friend" ,friend) ("extra" ,extra) ("sunday school" ,sunday-school) ("dues" ,dues) ("on time" ,on-time)))

(define (item-columns items)
  (map (cut car <>) items))

(define (item-funcs items)
  (map (cut cadr <>) items))

(define (csv-record s)
  (++ "\""
      (string-fold
       (lambda (c o)
         (++ o
             (if (char=? c #\")
                 "\"\""
                 (->string c))))
       ""
       s)
      "\""))

(define (csv-headers columns)
  (fold (lambda (c o) (++ o c ",")) "" columns))

(define (csv-rows club clubbers funcs)
  (fold
   (lambda (c o)
     (++ o
         (fold (lambda (f o)
                 (++ o
                     (csv-record (->string (apply f `(,club ,c))))
                     ","))
               ""
               funcs)
         "\n"))
   ""
   clubbers))

(define (csv-headers-date columns club)
  (fold (lambda (d o)
          (++ o
              (fold (lambda (c o)
                      (++ o d "-" c ","))
                    ""
                    columns)))
        ""
        (sorted-club-meetings club)))

(define (csv-rows-date club clubbers dates funcs)
  (fold
   (lambda (c o)
     (++ o
         (name club c)
         ","
         (fold (lambda (d o)
                 (++ o
                     (fold (lambda (f o)
                             (++ o
                                 (csv-record (if (apply f `(,club ,c ,d)) "1" "0"))
                                 ","))
                           ""
                           funcs)))
               ""
               dates)
         "\n"))
   ""
   clubbers))

(define (to-csv items club clubbers)
  (++ (csv-headers (item-columns items))
      "\n"
      (csv-rows club clubbers (item-funcs items))))

(define (output-clubbers club)
  (with-output-to-file (++ club "-clubbers.csv")
    (lambda () (display (to-csv clubber-items club
                           (db:list "clubs" club "clubbers"))))))

(define (output-parents club)
  (with-output-to-file (++ club "-parents.csv")
    (lambda () (display (to-csv parent-items club
                           (map (lambda (c) (primary-parent club c))
                                (db:list "clubs" club "clubbers")))))))

(define (output-clubber-dates club)
  (with-output-to-file (++ club "-attendance.csv")
    (lambda ()
      (display
       (++ "," ; first one blank
           (csv-headers-date (item-columns clubber-date-items) club)
           "\n"
           (csv-rows-date club (db:list "clubs" club "clubbers") (sorted-club-meetings club)
                          (item-funcs clubber-date-items)))))))
(output-clubber-dates s-church)


(define club "evangel-baptist-church1")
(define meets (sorted-club-meetings club))


(define (sorted-club-meetings club)
  (define (num-attendees club-meeting)
    (cdr club-meeting))
  (define (string->date< sd1 sd2)
    (date<? (string->date sd1 "~Y/~m/~d") (string->date sd2 "~Y/~m/~d")))
  (define (club-meeting-date club-meeting)
    (car club-meeting))
  (let ((cm (filter (lambda (meeting)
                      (> (num-attendees meeting) 0))
                    (club-meetings club))))
    (sort (map (lambda (m) (club-meeting-date m)) cm) string->date<)))

(define mem "anna-green")

(present club mem d1)
