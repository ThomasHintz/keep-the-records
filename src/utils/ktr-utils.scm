(module ktr-utils
  (;; params


   ;; procs
   week-start week-end todays-mm todays-dd todays-yy todays-yyyy clear-date-time
   date-as-year in-week?
   )

(import scheme chicken)
(use srfi-19 srfi-1)

;;;;;;;;;;;;;;;; date utils ;;;;;;;;;;;;;;;;
(define (todays-mm) (date->string (current-date) "~m"))
(define (todays-dd) (date->string (current-date) "~d"))
(define (todays-yy) (date->string (current-date) "~y"))
(define (todays-yyyy) (date->string (current-date) "~Y"))

(define (date-as-year d yyyy)
  (make-date (date-nanosecond d) (date-second d) (date-minute d) (date-hour d)
             (date-day d) (date-month d) yyyy))

(define (clear-date-time d)
  (make-date 0 0 0 0 (date-day d) (date-month d) (date-year d)))

(define (in-week? d1 d2)
  ; is d2 within the same week as d1
  (let ((week-start (date-subtract-duration d1 (make-duration days: (date-week-day d1))))
        (week-end (date-add-duration d1 (make-duration days: (- 6 (date-week-day d1))))))
    (and (date>=? d2 week-start) (date<=? d2 week-end))))

(define (week-start d)
  (date-subtract-duration d (make-duration days: (date-week-day d))))

(define (week-end d)
  (date-add-duration d (make-duration days: (- 6 (date-week-day d)))))


)
