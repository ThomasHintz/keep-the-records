(use awful mda-client)

(define (setup-demo u-name)
  ($session-set! 'user u-name)
  (user-name u-name "Demo User")
  (let ((c-name (number->string (random 1000000000))))
    ($session-set! 'club c-name)
    
    (user-club u-name c-name)
    (user-email u-name "demo@demo.com")
    
    (club-name c-name "Demo Club")
    
    (map (lambda (data)
           (let ((clubber (first data)))
             (name c-name clubber clubber)
             (grade c-name clubber (second data))
             (birthday c-name clubber (third data))
             (club-level c-name clubber (fourth data))
             (allergies c-name clubber (fifth data))
             (primary-parent c-name clubber (sixth data))
             (db:update-list (name->id clubber) "clubs" c-name "clubbers")
             (map (lambda (attend-list)
                    (let ((date (first attend-list)))
                      (map (lambda (points-for)
                             (cond ((eq? points-for 'p) (present c-name clubber date #t))
                                   ((eq? points-for 'b) (bible c-name clubber date #t))
                                   ((eq? points-for 'h) (handbook c-name clubber date #t))
                                   ((eq? points-for 'u) (uniform c-name clubber date #t))
                                   ((eq? points-for 'f) (friend c-name clubber date #t))))
                           (second attend-list))))
                  (seventh data))))
         '(("Jamie Farmer" "Pre-k" "2/25/2006" "Cubbies" "" "Ray Farmer"
            (("2012/10/06" (p b h)) ("2012/10/13" (p b h u)) ("2012/10/20" (p b h u)) ("2012/10/27" (p b h u))))
           ("John Farmer" "1" "3/4/2004" "Sparks" "" "Ray Farmer"
            (("2012/10/06" (p b h)) ("2012/10/13" (p b h u)) ("2012/10/20" (p h u)) ("2012/10/27" (p b h u))))
           ("Roy Johnson" "3" "4/2/2002" "TnT" "Wheat" "Dew Mountain"
            (("2012/10/06" (p h)) ("2012/10/13" (p h)) ("2012/10/27" (p))))
           ("Sara Snower" "4" "3/14/2001" "TnT" "" "Randy Acorn"
            (("2012/10/06" (p b h u)) ("2012/10/13" (p b h u)) ("2012/10/20" (p b h u f)) ("2012/10/27" (p b h u))))
           ("Sally Snower" "2" "1/1/2003" "Sparks" "Milk" "Randy Acorn"
            (("2012/10/06" (p b h u)) ("2012/10/13" (p b h u)) ("2012/10/20" (p b h u)) ("2012/10/27" (p b h u))))
           ("Mark Snower" "5" "7/4/2000" "TnT" "" "Randy Acorn"
            (("2012/10/06" (p b h u)) ("2012/10/13" (p b h u)) ("2012/10/20" (p b h u)) ("2012/10/27" (p b h u))))
           ("Allie Snower" "7" "4/11/1998" "Trek" "" "Randy Acorn"
            (("2012/10/06" (p b h u)) ("2012/10/13" (p b h u)) ("2012/10/20" (p b h u)) ("2012/10/27" (p b h u))))))
    
    (map (lambda (data)
           (let ((p-name (first data)))
             (parent-name c-name p-name p-name)
             (parent-spouse c-name p-name (second data))
             (parent-email c-name p-name (third data))
             (parent-phone-1 c-name p-name (fourth data))
             (parent-phone-2 c-name p-name (fifth data))
             (parent-address c-name p-name (sixth data))
             (parent-release-to c-name p-name (seventh data))
             (parent-children c-name p-name (eighth data))
             (db:update-list "name" "clubs" c-name "parents" p-name)
             (db:update-list "spouse" "clubs" c-name "parents" p-name)
             (db:update-list "email" "clubs" c-name "parents" p-name)
             (db:update-list "phone-1" "clubs" c-name "parents" p-name)
             (db:update-list "phone-2" "clubs" c-name "parents" p-name)
             (db:update-list "address" "clubs" c-name "parents" p-name)
             (db:update-list "release" "clubs" c-name "parents" p-name)
             (db:update-list "children" "clubs" c-name "parents" p-name)
             (db:update-list (name->id p-name) "clubs" c-name "parents")))
         '(("Ray Farmer" "Jill Farmer" "ray@gmail.com" "906.342.2341" "906.234.2623"
            "38182 Silver Creek Rd Houghton MI 49931" "Ray Farmer, Jill Farmer" ("Jamie Farmer" "John Farmer"))
           ("Dew Mountain" "Allie Mountain" "mda@gmail.com" "906.325.1323" "906.231.5622"
            "152 Houghon Ave Houghton MI 49931" "Dew Mountain, Allie Mountain" ("Roy Johnson"))
           ("Randy Acorn" "Melanie Acorn" "randy.acorn@yahoo.com" "906.262.1223" "906.242.3342"
            "2352 College Ave Houghton MI 49931" "Randy Acorn, Melanie Acorn" ("Sara Snower" "Sally Snower"
                                                                               "Mark Snower" "Allie Snower"))))))
