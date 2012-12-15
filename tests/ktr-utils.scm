(use test)

(load "../src/utils/ktr-utils.scm")
(use ktr-utils srfi-19)

(test-begin "all")

(test-group "clear-date-times"
            (test "12.20.3000:00:00:00"
                  (date->string (clear-date-time (make-date 1 1 1 1 20 12 3000))
                                "~m.~d.~Y:~T")))

(test-group "date-as-year"
            (test "12.20.2000:01:01:01"
                  (date->string (date-as-year (make-date 1 1 1 1 20 12 3000) 2000)
                                "~m.~d.~Y:~T")))

(test-group "in-week?"
            ; day 9 is a sunday
            (test #t (in-week? (make-date 0 0 0 0 9 1 2000)
                               (make-date 0 0 0 0 9 1 2000)))
            (test #t (in-week? (make-date 0 0 0 0 9 1 2000)
                               (make-date 0 0 0 0 15 1 2000)))
            (test #f (in-week? (make-date 0 0 0 0 9 1 2000)
                               (make-date 0 0 0 0 16 1 2000)))
            ; across month boundary
            (test #t (in-week? (make-date 0 0 0 0 30 1 2000)
                               (make-date 0 0 0 0 5 2 2000)))
            ; across year boundary
            (test #t (in-week? (make-date 0 0 0 0 30 12 1999)
                               (make-date 0 0 0 0 1 1 2000))))

(test-group "week-start/week-end"
            (test "12/09/12" (date->string (week-start (make-date 0 0 0 0 14 12 2012)) "~D"))
            (test "12/09/12" (date->string (week-start (make-date 0 0 0 0 15 12 2012)) "~D"))
            (test "12/09/12" (date->string (week-start (make-date 0 0 0 0 9 12 2012)) "~D"))
            ; across month boundary
            (test "11/25/12" (date->string (week-start (make-date 0 0 0 0 1 12 2012)) "~D"))
            ; across year boundary
            (test "12/30/12" (date->string (week-start (make-date 0 0 0 0 1 1 2013)) "~D"))

            (test "12/15/12" (date->string (week-end (make-date 0 0 0 0 14 12 2012)) "~D"))
            (test "12/15/12" (date->string (week-end (make-date 0 0 0 0 15 12 2012)) "~D"))
            (test "12/15/12" (date->string (week-end (make-date 0 0 0 0 9 12 2012)) "~D"))
            ; across month boundary
            (test "12/01/12" (date->string (week-end (make-date 0 0 0 0 25 11 2012)) "~D"))
            ; across year boundary
            (test "01/05/13" (date->string (week-end (make-date 0 0 0 0 30 12 2012)) "~D")))

(test-group "date-year+"
            (test "01/01/13" (date->string (date-year+ (make-date 0 0 0 0 1 1 2012) 1) "~D")))

(test-group "date-between?"
            (test #t (day/month-between? (make-date 0 0 0 0 10 1 2012)    ; 01/10/2012
                                    (make-date 0 0 0 0 05 1 2012)         ; 01/05/2012
                                    (make-date 0 0 0 0 12 1 2012)))       ; 01/12/2012

            (test #t (day/month-between? (make-date 0 0 0 0 10 1 2012)    ; 01/10/2012
                                    (make-date 0 0 0 0 05 1 2012)         ; 01/05 2012
                                    (make-date 0 0 0 0 12 2 2012)))       ; 01/12/2012

            (test #t (day/month-between? (make-date 0 0 0 0 10 1 2012)    ; 01/10/2012
                                    (make-date 0 0 0 0 05 1 2011)         ; 01/05/2011
                                    (make-date 0 0 0 0 12 2 2013)))       ; 02/12/2013

            (test #f (day/month-between? (make-date 0 0 0 0 10 1 2012)    ; 01/10/2012
                                    (make-date 0 0 0 0 15 1 2012)         ; 01/15/2012
                                    (make-date 0 0 0 0 12 2 2012)))       ; 02/12/2012

            (test #f (day/month-between? (make-date 0 0 0 0 10 10 2012)   ; 10/10/2012
                                    (make-date 0 0 0 0 15 1 2012)         ; 01/15/2012
                                    (make-date 0 0 0 0 12 2 2012))))      ; 02/12/2012

(test-end "all")
