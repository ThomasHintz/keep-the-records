(use pdf srfi-1)

(define (if-first l)
  (if (> (length l) 0) (first l) ""))
(define (if-second l)
  (if (> (length l) 1) (second l) ""))
(define (if-third l)
  (if (> (length l) 2) (third l) ""))
(define (if-fourth l)
  (if (> (length l) 3) (fourth l) ""))
(define (if-fifth l)
  (if (> (length l) 4) (fifth l) ""))
(define (if-sixth l)
  (if (> (length l) 5) (sixth l) ""))

(define-syntax dotimes
  (syntax-rules ()
    ((_ (index maxval) body ...)
     (do ((index 0 (+ index 1)))
       ((= index maxval))
       body ...))))

(import (prefix pdf pdf:))

;(define font (make-parameter (pdf:build-font "Helvectica")))
(define font-size (make-parameter 18))
(define line-height-mult (make-parameter 1.5))
(define line-height (make-parameter (* (font-size) (line-height-mult))))
(define row-padding (make-parameter (/ (- (line-height) (font-size)) 2)))
(define col-padding (make-parameter 4))

(define line-left (make-parameter 25))
(define line-top (make-parameter (- 750 (line-height))))
(define original-line-top (make-parameter (line-top)))

(define page-ht (make-parameter 705))
(define rows-per-page (make-parameter (floor (/ (page-ht) (line-height)))))

(define (make-row . text)
  (let ((c1 200) (c2 150) (c3 75) (c4 125) (radius 0))
    (pdf:rectangle (line-left) (line-top) c1 (line-height) radius)
    (line-left (+ (line-left) c1))
    (pdf:rectangle (line-left) (line-top) c2 (line-height) radius)
    (line-left (+ (line-left) c2))
    (pdf:rectangle (line-left) (line-top) c3 (line-height) radius)
    (line-left (+ (line-left) c3))
    (pdf:rectangle (line-left) (line-top) c4 (line-height) radius)
    (pdf:stroke)
    (line-left (- (line-left) (+ c1 c2 c3)))

    (pdf:move-text (+ (line-left) (col-padding)) (+ (line-top) (row-padding)))
    
    (pdf:draw-text (if-first text))
    (pdf:move-text c1 0)
    (pdf:draw-text (if-second text))
    (pdf:move-text c2 0)
    (pdf:draw-text (if-third text))
    (pdf:move-text c3 0)
    (pdf:draw-text (if-fourth text))

    (pdf:move-text (- (+ (line-left) c1 c2 c3 (col-padding))) (- (+ (line-top) (row-padding))))
    (line-top (- (line-top) (line-height)))))

(define (pdf-release-form names file-path)
  (pdf:with-document-to-file file-path
    (let ((helvetica (pdf:build-font "Helvetica"))
          (pages (ceiling (/ (length names) (- (rows-per-page) 1)))))
      (dotimes (i pages)
               (line-top (original-line-top))
               (pdf:with-page
                (pdf:in-text-mode
                 (pdf:set-font (pdf:font-name helvetica) (font-size))
                 (make-row "Child's Name" "Parent Signature" "" "Picked Up?")
                 (let ((rows-current-page (if (> (length names) (- (rows-per-page) 1))
                                              (rows-per-page)
                                              (length names))))
                        (dotimes (ri rows-current-page)
                          (make-row (first names))
                          (set! names (drop names 1))))))))))