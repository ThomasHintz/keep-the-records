`("Awana Data" (("Cubbies" (("Hopper" (("Bear Hug Brochure" (1 2))
				       ("Hopper Trail" (1 2))
				       ("Lamb Path 1" (1 2))
				       ("Elephant Walk 1" (1 2))
				       ("Lamb Path 2" ,(range 1 3))
				       ("Elephant Walk 2" ,(range 1 3))
				       ("Lamb Path 3" ,(range 1 3))
				       ("Elephant Walk 3" ,(range 1 3))
				       ("Lamb Path 4" ,(range 1 3))
				       ("Elephant Walk 4" ,(range 1 3))
				       ("Under the Apple Tree" ,(range 1 25))
				       ("Character Builder" ,(range 1 21))))
			    ("Jumper" (("asdf" (1 2))
				       ("qwerty" (1 2))))))
		("Sparks" (("sparks book 1" (("sc1" (1 2))
					     ("sc2" (1 2 3))))
			   ("sparks book 2" (("sb1" (1 2))
					     ("sb2" (1 2))))))
		("TnT" ,(cons `("Start Zone" (("Start Zone" ,(range 1 8))))
			      (map (lambda (book-n)
				     `(,(string-append "Book " (number->string book-n))
				       ,(append (map (lambda (discovery-n)
						       `(,(string-append "Discovery " (number->string discovery-n)) ,(range 1 8)))
						     (range 1 8))
						(map (lambda (silver-n)
						       `(,(string-append "Silver " (number->string silver-n)) (1)))
						     (range 1 8))
						(map (lambda (gold-n)
						       `(,(string-append "Gold " (number->string gold-n)) (1 2)))
						     (range 1 8)))))
				   (range 1 5))))))