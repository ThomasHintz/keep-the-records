(use awful html-tags html-utils)

(load "utils.scm")

(enable-ajax #t)

(define (define-awana-page path content #!key
          (css '()) (title "Keep The Records - Awana Recordkeeping") (no-session #t) (login-path #f) (no-ajax #t)
          (headers "") (page-title #f)
          (header-bottom "")
          (main-url "/") (app-title "Keep The Records") (app-subtitle "Awana Record Keeping")
          (main-nav '(("/tour" "Tour") ("/plans-pricing" "Plans & Pricing") ("/sign-up" "Sign up!")))
          (top-nav '(("/about" "About") ("/blog" "Blog") ("/contact" "Contact"))))
  (define-page path
    (lambda (actual-path)
      (++ (<body> class: "home page page-template"
                  (<div> class: "header"
                         (<div> (<div> (<div> class: "center"
                                              (<a> href: main-url (<h1> class: "logo" app-title)
                                                   (<h2> class: "logo" app-subtitle))
                                              (<div> class: "header-right"
                                                     (<div> class: "topnav"
                                                            (<ul> id: "menu-top-links" class: "menu"
                                                                  (fold (lambda (e o)
                                                                          (++ o (<li> class: "menu-item"
                                                                                      (<a> href: (first e)
                                                                                           (second e))))) ""
                                                                                      top-nav)))
                                                     (<div> class: "nav"
                                                            (<ul> id: "menu-main-links" class: "menu"
                                                                  (fold (lambda (e o)
                                                                          (++ o (<li> class: "menu-item"
                                                                                      (<a> href: (first e)
                                                                                           (second e))))) ""
                                                                                      main-nav))))
                                              (if page-title (<div> class: "page-title" (<h2> page-title)) "")
                                              header-bottom))))
                  (<div> class: "container" (<div> class: "center" (content actual-path))))))
    css: (append '("/css/saas-common.css" "/css/saas-griddler.css" "/css/saas-default.css") css)
    title: title
    no-session: no-session
    no-ajax: no-ajax
    ;headers: (++ (insert-file "analytics.html")))
    headers: headers))

(define plans-pricing-url (make-parameter "/plans-pricing"))

(define (make-home-page #!key (tag-line "") (tag-line-desc "") (screenshots '()) (features '()))
  (define-awana-page (regexp "/")
    (lambda (path)
      (++ (<div> class: "features"
                 (<ul> (fold (lambda (e o)
                               (++ o (<li> (<div> class: "icon" (<img> src: (first e)))
                                           (<div> class: "content" (<h3> (second e)) (<p> (third e))))))
                             ""
                             features)))))
    header-bottom:
    (++ (<div> class: "proms" style: "height: 350px;"
               (<div> class: "left"
                      (<h2> tag-line)
                      (<p> tag-line-desc)
                      (<a> class: "radius button" href: (plans-pricing-url) "See Plans & Pricing"))
               (<div> class: "right"
                      (<p> id: "prom1" class: "ui-tabs-panel ui-widget-content ui-corner-bottom"
                           (<img> src: (first (first screenshots))))
                      (<p> id: "prom2" class: "ui-tabs-panel ui-widget-content ui-corner-bottom ui-tabs-hide"
                           (<img> src: (first (second screenshots))))
                      (<p> id: "prom3" class: "ui-tabs-panel ui-widget-content ui-corner-bottom ui-tabs-hide"
                           (<img> src: (first (third screenshots))))
                      (<p> id: "prom4" class: "ui-tabs-panel ui-widget-content ui-corner-bottom ui-tabs-hide"
                           (<img> src: (first (fourth screenshots))))
                      (<div> class: "controller ui-tabs ui-widget ui-widget-content ui-corner-all"
                             (<ul> class: "ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all"
                                   (<li> class: "ui-state-default ui-corner-top ui-tabs-selected ui-state-active"
                                         (<a> href: "#prom1" class: "first" (second (first screenshots))))
                                   (<li> class: "ui-state-default ui-corner-top"
                                         (<a> href: "#prom2" (second (second screenshots))))
                                   (<li> class: "ui-state-default ui-corner-top"
                                         (<a> href: "#prom3" (second (third screenshots))))
                                   (<li> class: "ui-state-default ui-corner-top"
                                         (<a> href: "#prom4" (second (fourth screenshots)))))))))
  headers: (include-javascript "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.6/jquery-ui.min.js")
  no-ajax: #f))

(define (fold-sep proc sep start list)
  (let ((first #t))
    (fold (lambda (e o)
            (++ o (if first (begin (set! first #f) "") sep) (proc e)))
          start
          list)))

(define (string-fold proc list)
  (fold-sep proc "" "" list))

(define (string-fold-sep proc sep list)
  (fold-sep proc sep "" list))

; tours structure '(url icon-img name subtitle subtext (specifics) screenshot)
(define (make-tour-page #!key (tours '()))
  (define-page "/tour" (lambda () (redirect-to (++ "/tour/" (first (first tours))))))
  (define-awana-page (regexp (++ "/tour/(" (string-fold-sep (lambda (e) (++ "(" (first e) ")")) "|" tours) ")"))
    (lambda (path)
      (let* ((feature (second (string-split path "/")))
             (feature-details (find (lambda (e) (string=? feature (first e))) tours)))
        (++ (<div> class: "sidebar left"
                   (<div> class: "submenu radius"
                          (<ul> (string-fold (lambda (e)
                                               (<li> class: (++ "page_item" (if (string=? (first e) feature)
                                                                                " current_page_item" ""))
                                                     (<a> href: (++ "/tour/" (first e))
                                                                             (<img> src: (++ "/images/" (second e))
                                                                                    (third e)))))
                                             tours))))
            (<div> class: "content"
                   (<h3> (third feature-details))
                   (<p> (<img> class: "alignright" src: (++ "/images/" (seventh feature-details))))
                   (<h4> (fourth feature-details))
                   (<p> (fifth feature-details))
                   (<ul> class: "clear"
                         (let ((left #f))
                           (string-fold (lambda (e)
                                          (set! left (not left))
                                          (<li> class: (if left "left" "right")
                                                (<h4> (<img> src: (++ "/images/" (first e)) class: "v-bt")
                                                      (second e))
                                                (<p> (third e))))
                                        (sixth feature-details))))))))
    page-title: "Tour"))

(make-home-page tag-line: "Give more to the kids!"
               tag-line-desc: "Do away with the paper, with the copier, with the calculator. Welcome electronic Awana record keeping made easy! Easily take attendance. Quickly find clubber info. Manage hundreds or thousands of clubbers easily."
               screenshots: '(("/images/screenshot.png" "Screenshot") ("/images/screenshot.png" "Screenshot")
                              ("/images/screenshot.png" "Screenshot") ("/images/screenshot.png" "Screenshot"))
               features: '(("/images/i_calendar.png" "Take Attendance" "Get rid of the spreadsheets and graph paper. It's time to quickly and easily take attendance.")
                           ("/images/i_buoy.png" "Find Clubber Info" "What if someone gets injured and you need to call their parents? Quickly search or browser for their name and view their attached contact info. It may save a life.")
                           ("/images/i_clock.png" "Manage Hundreds of Clubbers" "It's painful to keep paper records of hundreds of Awana clubbers. With Keep The Records, it is easy with searches, filters, and categories.")
                           ("/images/i_basket.png" "No More Copies" "You no longer need to make copies of everything for all of the leaders. Just give a leader access, and Keep The Records will allow them to view and manage all of the clubbers and view stats for the club.")))

; tours structure '(url icon-img name subtitle subtext (specifics) screenshot)
; specifics '(icon-img title text)
(make-tour-page tours: '(("find-clubbers" "i_buoy.png" "Find Clubbers" "Find Clubbers Quickly and Easily"
                          "With KtR it is easy to quickly find clubbers. You can view all of the members in your club, or filter it down into smaller groups like 'Cubbies' or 'Sparkies'. You can also do a text search, or sort by first or last name."
                          (("i_global.png" "Search" "Have hundreds or even thousands of clubbers? No problem, you can search through all of the club members to quickly find info on the clubber you are looking for.")
                           ("i_download.png" "Filter" "Want to view just the clubbers in Sparks? It's easy. Just click on the matching tab and you will be able to view just the club members in that club. You can also search and sort within clubs.")
                           ("i_stock.png" "Sort" "You can sort by first name or last. You can even sort, filter, and search; all at the same time.")
                           ("i_stick.png" "Emergencies" "If there is an emergency, you need to be able be contact the clubber's parents as fast as you can. With KtR you can quickly search for the clubber and view the contact information in just a few seconds.")) "members-screenshot.png")
                         ("take-attendance" "i_calendar.png" "Take Attendance" "Record Attendance and Other Stats"
                          "Taking attendance of hundreds or thousands of Awana clubbers is really difficult on paper, and digital spreadsheets are not much better. With KtR it is really quick and easy. Just start typing the name of a clubber and the list will filter down as you type. Then you can either click the attendance buttons are just use the keyboard shortcuts. With KtR you can cut the time it takes to check someone in to about 5 seconds no matter how many people you have to check in."
                          (("i_global.png" "Filter" "I had a tough time taking attendance with over a hundred clubbers registered. With KTR though, there is a filter, that pares down the list of clubbers as you type, allowing you to quickly find a clubber and take attendance.")
                           ("i_download.png" "Attendance, Handbook, Bible, Uniform, Friend" "As you take attendance you can also mark down if the clubber brought their handbook, Bible, uniform, and a friend. KTR also records points, so that you can reward those that do best.")) "attendance-filter-screenshot.png")
                         ("view-clubber-info" "i_clock.png" "View Clubber Info" "Quickly Find Emergency Contacts"
                          "With KtR it is easy to quickly find clubbers. You can view all of the members in your club, or filter it down into smaller groups like 'Cubbies' or 'Sparkies'. You can also do a text search, or sort by first or last name."
                          () "member-info-screenshot.png")
                         ("view-allergy-watch-list" "i_basket.png"
                          "View Allergy Watch List" "Don't let An Allergic Reaction Happen"
                          "Keeping track of who has what allergies in what club isn't always easy. And you need to be on top of this game; no one wants someone having a severe allergic reaction when it could have been prevented. Keep The Records automatically produces an up-to-date allergy watch list for viewing or printing. Keep the kids safe."
                          () "watch-list-screenshot.png")))