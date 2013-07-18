(use srfi-13)

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

(define (to-csv items club clubbers)
  (++ (csv-headers (item-columns items))
      "\n"
      (csv-rows club clubbers (item-funcs items))))

(define (sorted-club-meetings club)
  (define (num-attendees club-meeting)
    (cdr club-meeting))
  (define (string->date> sd1 sd2)
    (date>? (string->date sd1 "~Y/~m/~d") (string->date sd2 "~Y/~m/~d")))
  (define (club-meeting-date club-meeting)
    (car club-meeting))
  (let ((cm (filter (lambda (meeting)
                      (> (num-attendees meeting) 0))
                    (club-meetings club))))
    (sort (map (lambda (m) (club-meeting-date m)) cm) string->date>)))
