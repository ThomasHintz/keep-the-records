(ad: list   club-level 
     select book
	    chapter
	    section)

(ad: club-level) ; returns a list of all the clubs
(ad: "TnT" "Book 1" chapter) ; returns a list of the chapters in TnT book 1
(ad: "TnT" "Book 2" chapter section) ; returns a list of chapters and sections for TnT book 2
(ad: "Cubbies" "Skipper" "Lamb Path 2" section) ; returns a list of sections for Cubbies book Skipper chapter Lamb Path 2
(ad: club-level book chapter section) ; returns a list of all the awana data
(ad: "Sparks" book chapter) ; returns a list of books and corresponding chapters [but not sections] for the Sparks club

(cd: section "grace-bible-church0" "sally-java") ; = (ad: clubbers-current-club-level clubbers-current-book clubbers-current-chapter section)
(cd: book "grace-bible-church0" "sally-java") ; = (ad: clubbers-current-club-level book)
(cd: book chapter) ; = (ad: book chapter clubbers-current-club-level)