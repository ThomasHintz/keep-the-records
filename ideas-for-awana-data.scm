(ad: list   club-level 
     select book
	    chapter
	    section)

(ad: club-level) ; returns a list of all the clubs
(ad: chapter "TnT" "Book 1") ; returns a list of the chapters in TnT book 1
(ad: chapter section "TnT" "Book 2") ; returns a list of chapters and sections for TnT book 2
(ad: section "Cubbies" "Skipper" "Lamb Path 2") ; returns a list of sections for Cubbies book Skipper chapter Lamb Path 2
(ad: club-level book chapter section) ; returns a list of all the awana data
(ad: book chapter "Sparks") ; returns a list of books and corresponding chapters [but not sections] for the Sparks club

(cd: section "grace-bible-church0" "sally-jave") ; = (ad: section clubbers-current-club-level clubbers-current-book clubbers-current-chapter)
(cd: book "grace-bible-church0" "sally-java") ; = (ad: book clubbers-current-club-level)
(cd: book chapter) ; = (ad: book chapter clubbers-current-club-level)


(ad: club-level) = (map (lambda (cll) (first cll)) (second ad))
(ad: club-level book) = (map (lambda (cll)
			       `(,(first cll)
				 ,(map (lambda (bl)
					 (first bl))
				       (second cll))))
			     (second ad))
;;;



(ad: book "TnT") = (map (lambda (bl)
			  (first bl))
			(second (first (filter (lambda (cll)
						 (string=? (first cll) "TnT"))
					       (second ad)))))
(ad: chapter "TnT" "Book 2") = (map (lambda (sl)
				      (first sl))
				    (second (first (filter (lambda (bl)
							     (string=? (first bl) "Book 2"))
							   (second (first (filter (lambda (cll)
										    (string=? (first cll) "TnT"))
										  (second ad))))))))