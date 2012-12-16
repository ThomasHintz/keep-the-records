(define (date->date-year d yyyy)
  (if d (make-date 0 0 0 0 (date-day d) (date-month d) yyyy) #f))

(define (in-week? d1 d2)
  ; is d2 within the same week as d1
  (let ((week-start (date-subtract-duration d1 (make-duration days: (date-week-day d1))))
        (week-end (date-add-duration d1 (make-duration days: (- 6 (date-week-day d1))))))
    (and (date>=? d2 week-start) (date<=? d2 week-end))))

(define (birthdays-within club clubbers d1 d2)
    (filter (lambda (c)
              (let* ((c-b (birthday club c))
                     (c-bd (and c-b (db->date c-b)))
                     (c-bd-c (and c-b (date->date-year c-bd (string->number (todays-yyyy))))))
                (and c-bd-c (date>=? c-bd-c d1) (date<=? c-bd-c d2))))
            clubbers))

(define (week-start d)
  (date-subtract-duration d (make-duration days: (date-week-day d))))

(define (week-end d)
  (date-add-duration d (make-duration days: (- 6 (date-week-day d)))))

(define (current-date-0000)
  (make-date 0 0 0 0 (string->number (todays-dd)) (string->number (todays-mm)) (string->number (todays-yyyy))))
