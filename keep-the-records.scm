;;; WARNING user/club names should be cleaned, null and / are illegal characters

(use numbers) ;; !IMPORTANT! needs to come before other eggs, may segfault otherwise (020111)
(use awful message-digest-port sha2 posix http-session
     spiffy-cookies html-tags html-utils srfi-13 srfi-19 regex srfi-69 doctype http-session srfi-18 crypt uri-common spiffy intarweb)

(load "src/utils/macs") (import macs)
(load "src/db/db-interface") (import db-interface)
(load "src/utils/misc-utils") (import misc-utils)
(load "storage-funcs")
(load "demo-data")
(load "handlers")
(load "pdf")
(load "src/sections/sections") (import sections)
(load "rest")
(load "sessions")
(load "src/utils/date-time-utils") (import date-time-utils)

(include "etc/database.scm")
(db:connect)

(define is-production? (make-parameter (file-exists? "~/keep-the-records/i-am-production")))

;;; production
(if (is-production?) (load "production") #f)

;;; spiffy settings
(index-files '())

;;; Settings

(enable-ajax #t)
(ajax-library "https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.min.js")
(enable-session #t)
(enable-web-repl "/web-repl")

(session-cookie-setter
 (lambda (sid)
   (set-cookie! (session-cookie-name) sid secure: (is-production?) http-only: #t)))

(define (developer-access?)
  (or (development-mode?) (string=? ($session 'user) "t@thintz.com")))

(web-repl-access-control developer-access?)

(valid-password?
 (lambda (user password)
   (if (eq? (user-email user) 'not-found)
       #f
       (password-matches? user password))))

;(when (not (db:db)) (db:db (db:open-db "ktr-db")))

(define (ktr-ajax club url selector action proc #!key (success #f) (arguments '()) (live #f) (method 'POST) (target #f)
		  (update-targets #f) (prelude #f))
  (ajax url selector action
	(lambda ()
           (with-output-to-file "first" (lambda () (print "good")))
	  (when (not (or (equal? ($session 'club) ($ 'club ""))
			 (string=? ($session 'user) "t@thintz.com")))
		(abort 'permission-denied))
	  (handle-exceptions
           exn
           (let ((c (with-output-to-string (lambda () (print-call-chain)))))
             (thread-start!
              (make-thread
               (lambda ()
                 (send-mail subject: "KtR Error"
                            text: (with-output-to-string
                                    (lambda ()
                                      (display c)
                                      (print-error-message exn)
                                      (newline)
                                      (when uri-path (write (uri-path (request-uri (current-request)))))
                                      (newline)
                                      (if (session-valid? (read-cookie (session-cookie-name)))
                                          (let ((user ($session 'user)))
                                            (newline)
                                            (display (++ "user: " (->string user)))
                                            (newline)
                                            (display (++ " user name: " (->string (user-name user))))
                                            (newline)
                                            (display (++ " user club: " (->string (user-club user)))))
                                          (write ""))))
                            from: "errors@keeptherecords.com"
                            from-name: "Thomas Hintz"
                            to: "errors@keeptherecords.com"
                            reply-to: "errors@keeptherecords.com"))))
             (abort exn))
           (proc ($ 'club))))
	success: success
	arguments: (append arguments '((club . "club")))
	live: live
	method: method
	update-targets: update-targets
	prelude: prelude
	target: target)
  (++ "var club = '" club "';"))

(define (is-current? url path)
  (if (string-match (regexp (++ url ".*")) path)
      #t
      #f))

(define (main-tab-class is-current)
  (++ "main-tab-item" (if is-current " main-tab-item-current" "")))

(define (define-awana-app-page path content #!key
          (css '())
          (title "Keep The Records")
          (no-session #f)
          (login-path #f)
          (headers "")
	  (method 'GET)
          (no-ajax #t)
          (tab 'none))
  (define-page (if (regexp? path) path (regexp path))
    (lambda (actual-path)
      (handle-exceptions
       exn
       (if (eq? exn 'permission-denied)
           "PERMISSION DENIED! If you think this is an error, please email me at t@keeptherecords.com"
           (abort exn))
       (let ((club (first (string-split actual-path "/"))))
         (when (and (not (or (string=? club "user") (string=? club "club") (string=? club "sign-up") (string=? club "process-sign-up")))
                    (not (or (string=? ($session 'club) club) (string=? ($session 'user) "t@thintz.com"))))
           (abort 'permission-denied))
         (++ (include-javascript "/js/errorception.js")
             (if (and (session-valid? (read-cookie "awful-cookie")) ($session 'demo))
                 (<div> class: "demo container_12"
                        (<div> class: "demo-contents"
                               "This is a DEMO"
                               " "
                               (<a> class: "demo-sign-up" href: "http://keeptherecords.com/plans-pricing"
				    "Interested in the full version?")))
                 "")
             (<div> class: "container_12"
                    (if (and (session-valid? (read-cookie "awful-cookie")) ($session 'user))
                        (<div> class: "grid_12 info-bar text-right full-width"
                           (user-name ($session 'user)) " | "
                           (<a> href: (++ "/" club "/account-settings") "My Info") " | "
                           (<a> href: "/sign-out" "Signout"))
                        "")
                    (if (neq? tab 'none)
                        (<div> class: "grid_12 menu-bar full-width"
                               (<div> class: "mmi-c"
                                      (folds* (lambda (str url)
                                                (<a> class: (++ "main-menu-item"
                                                                (if (eq? tab (string->symbol (string-downcase str)))
                                                                    " main-menu-item-current" ""))
                                                     href: (++ "/" club "/" (string-downcase str) "/" url) str))
                                              '(("Clubbers" "find")
                                                ;("Leaders" "find")
                                                ;("Stats" "attendance")
                                                ("Admin" "leaders"))))
                               (<div> class: "logo"
                                      (<a> class: "main-logo" href: "http://keeptherecords.com" "Keep The Records")))
                        "")
                    (<div> class: "grid_12 main-tab-bar full-width"
                           (cond
                            ((eq? tab 'clubbers)
                             (folds* (lambda (t)
                                       (<a> href: (++ "/" club "/clubbers/" (string-downcase t))
                                            class: (main-tab-class (is-current? (++ "/" club "/clubbers/"
                                                                                    (string-downcase t)) actual-path))
                                            t))
                                     '(("Dashboard") ("Attendance")
				       ;("Awards")
				       ("Find") ("Release") ("Sections"))))
                            ((eq? tab 'leaders)
                             (folds* (lambda (t)
                                       (<a> href: (++ "/" club "/leaders/" (string-downcase t))
                                            class: (main-tab-class (is-current? (++ "/" club "/leaders/"
                                                                                    (string-downcase t)) actual-path))
                                            t))
                                     '(("Find"))))
                            ((eq? tab 'stats)
                             (++ (<a> href: (++ "/" club "/stats/attendance")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/stats/attendance") actual-path))
                                      "Attendance")
                                 (<a> href: (++ "/" club "/stats/sections")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/stats/sections") actual-path))
                                      "Sections")
                                 (<a> href: (++ "/" club "/stats/club")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/stats/club") actual-path))
                                      "Club")))
                            ((eq? tab 'admin)
                             (++ (<a> href: (++ "/" club "/admin/leaders")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/admin/leaders") actual-path))
                                      "Leaders")
                                 (<a> href: (++ "/" club "/admin/clubbers")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/admin/clubbers") actual-path))
                                      "Clubbers")))
                            ((eq? tab 'none) "")))
                    (<div> class: "selected-tab-container" (if (regexp? path) (content actual-path) (content))))))))
    css: (append '("https://fonts.googleapis.com/css?family=Tangerine:regular,bold&subset=latin"
                   "https://fonts.googleapis.com/css?family=Neucha&subset=latin"
                   "https://fonts.googleapis.com/css?family=Josefin+Sans+Std+Light"
                   "https://fonts.googleapis.com/css?family=Vollkorn&subset=latin"
                   "https://fonts.googleapis.com/css?family=Permanent+Marker"
                   "/css/reset.css" "/css/960.css" "/css/master.css?ver=6") css)
    title: title
    method: method
    no-session: no-session
    no-ajax: no-ajax
    headers: headers ; (++ (insert-file "analytics.html") headers)
    doctype: doctype-html))

;;; development reload

(define-page "/reloadme"
  (lambda ()
    (when (developer-access?)
      (load-apps (awful-apps))
      "Reloaded"))
  no-session: #t)

;;; club/user create

(define-awana-app-page (regexp "/sign-up/club-create/(free|basic|plus|premier|ultimate)")
  (lambda (path)
    (add-javascript "$(document).ready(function() { $('#club-register-form').validationEngine('attach'); $('#church').focus(); });")
    (let ((plan (third (string-split path "/"))))
      (<div> class: "grid_12"
	     (<span> class: "have-account"
		     "* Want to use an existing account? "
		     (<a> href: (++ "/sign-up/payment/" plan) "click here to do so"))
	     (<br>)
	     (<br>)
	     (<form> action: (++ "/club/create/" plan) id: "club-register-form" method: 'POST
		     (<h1> class: "action" "Create Club")
		     (<span> class: "form-context" "Church or Association Name") (<br>)
		     (<input> class: "text validate[required,custom[onlyLetterSp]]" type: "text" id: "church" name: "church")
		     (<h1> class: "action" "Create Your Account")
		     (<span> class: "form-context" "Name") (<br>)
		     (<input> class: "text validate[required,custom[onlyLetterSp],custom[ktr-name]]" type: "text" id: "name" name: "name") (<br>)
		     (<span> class: "form-context" "Email") (<br>)
		     (<input> class: "text validate[required,custom[email]" type: "text" id: "email" name: "email") (<br>)
		     ;; (<span> class: "form-context" "Phone") (<br>)
		     ;; (<input> class: "text validate[custom[ktr-phone]]" type: "text" id: "phone" name: "phone") (<br>)
		     ;; (<span> class: "form-context" "Birthday") (<br>)
		     ;; (<input> class: "text validate[custom[ktr-date]]" type: "text" id: "birthday" name: "birthday") (<br>)
		     ;; (<span> class: "form-context" "Address") (<br>)
		     ;; (<input> class: "text" type: "text" id: "address" name: "address") (<br>)
		     (<span> class: "form-context" "Password") (<br>)
		     (<input> class: "text validate[required,minSize[16]]" type: "password" id: "password" name: "password") (<br>)
		     (<span> class: "form-context" "Password Again") (<br>)
		     (<input> class: "text validate[required,equals[password]]" type: "password" id: "password-again" name: "password-again") (<br>)
		     (<input> type: "submit" value: "Create Club" class: "submit-button button button-blue")))))
  css: '("/css/validation-engine.jquery.css" "/css/club-register.css?v=3")
  headers: (++ (include-javascript "/js/jquery.validation-engine.js")
	       (include-javascript "/js/jquery.validation-engine-en.js"))
  no-ajax: #f
  title: "Create club - KtR"
  no-session: #t
  tab: 'none)

;;; user login/create

(define (generate-password password)
  (crypt password))

(define (password-matches? user password)
  (if (and (eq? (user-pw-type user) 'sha512) (string=? (call-with-output-digest (sha512-primitive) (cut display password <>)) (user-pw user)))
      (begin (user-pw user (generate-password password))
	     (user-pw-type user 'crypt)
	     #t)
      (string=? (crypt password (user-pw user)) (user-pw user))))

(define (send-welcome-email email club name)
  (send-mail subject: "Welcome to Keep The Records - Awana Record Keeping"
             from: "t@keeptherecords.com"
             from-name: "Keep The Records"
             to: email
             reply-to: "t@keeptherecords.com"
             html: (++ (<p> "Welcome, " name "!")
                       (<p> "You now have access to " (club-name club) "'s Keep The Records, Awana Record Keeping program. To login and start using the program you can go to " (<a> href: "https://a.keeptherecords.com" "https://a.keeptherecords.com") ". You can also find the login link at the KtR blog - " (<a> href: "http://keeptherecords.com" "http://keeptherecords.com") ".")
                       (<p> "If you ever have any questions or just want to give me feedback, just email Thomas Hintz at " (<a> href: "mailto:t@keeptherecords.com" "t@keeptherecords.com") ". Also, please feel free to follow the KtR blog at " (<a> href: "http://keeptherecords.com/blog" "http://keeptherecords.com/blog") ".")
                       (<p> "If you enjoy using KtR, than please recommend it to your friends. I want to help as many Awana clubs as I can. Taking good records and being able to see what works and what doesn't is critical to running a great Awana program.")
                       (<p>)
                       (<p> "Thanks and God Bless!")
                       (<p> "Thomas Hintz - Creator of KtR"))))

(define-login-trampoline "/login-trampoline"
  hook: (lambda (user)
          (if (sid)
              (begin ($session-set! 'user user)
                     ($session-set! 'club (user-club user)))
              #f)))

(login-page-path "/user/login")
(define-awana-app-page (login-page-path)
  (lambda ()
    (add-javascript "$(document).ready(function() { $('#user').focus(); });")
    (<div> class: "grid_12"
           (<h1> class: "action" "Login to Keep the Records")
           (<form> action: "/login-trampoline" method: 'POST
		   (<div> style: (if (equal? ($ 'reason "") "invalid-password") "" "display: none;")
			  (<span> class: "form-context" style: "color: red;"
				  "Your user name or password is incorrect, please try again.")
			  (<br>)
			  (<span> class: "form-context" style: "color: red;"
				  "If you need to reset your password, email t@keeptherecords.com.")
			  (<br>)
			  (<br>))
                   (<span> class: "form-context" "Email") (<br>)
                   (<input> class: "text" type: "text" id: "user" name: "user"
			    value: (if (not (equal? #f ($ 'user #f))) ($ 'user) "")) (<br>)
                   (<span> class: "form-context" "Password") (<br>)
                   (<input> class: "text" type: "password" id: "password" name: "password") (<br>)
                   (<input> class: "button button-blue" type: "submit" value: "Enjoy KtR!"))))
  no-ajax: #f
  css: '("/css/club-register.css?ver=2")
  no-session: #t)

(define-page (regexp "/sign-out")
  (lambda (path)
    (session-destroy! (read-cookie "awful-cookie"))
    (delete-cookie! "awful-cookie") ;  conflicts with http-session cookie
    (redirect-to "/user/login")))

(define-awana-app-page (regexp "/[^/]*/join-club")
  (lambda (path)
    (++ (<h1> "Join A Club")
        "To begin, you must be authorized to work with an Awana club."
        (<br>) (<br>)
        "You can either:"
        (<ul> (<li> (<a> href: "/club/authorize-me" "Ask for authorization from an existing club"))
              (<li> (<a> href: "/club/register" "Create a new club"))))))

(define (as-db-unique proc unique-val start-val)
  (when (> start-val 20000) (abort 'no-unique-val-found))
  (if (eq? (proc (++ unique-val (number->string start-val))) 'not-found)
      (++ unique-val (number->string start-val))
      (as-db-unique proc unique-val (+ start-val 1))))

;;; demo pages

(define-page "/demo"
  (lambda ()
    (let ((new-sid (session-create)))
      (sid new-sid)
      (set-cookie! (session-cookie-name) new-sid)
      ($session-set! 'demo #t)
      (let ((u-name (number->string (random 1000000000))))
        (setup-demo u-name)
        (html-page
         ""
         headers: (<meta> http-equiv: "refresh"
                          content: (++ "0;url=/" (user-club u-name) "/clubbers/dashboard"))))))
  no-session: #t)

;;; club pages

(define-awana-app-page (regexp "/club/create/(free|basic|plus|premier|ultimate)")
  (lambda (path)
    (let* ((plan (third (string-split path "/")))
	   (church ($ 'church))
           (club (as-db-unique (lambda (c) (club-name c)) (name->id church) 0))
           (u-name ($ 'name))
           (u-email ($ 'email))
           (u-phone ($ 'phone))
           (u-birthday ($ 'birthday))
           (u-address ($ 'address))
           (u-pw ($ 'password))
           (u-pw2 ($ 'password-again)))
      (if (and (string=? u-pw u-pw2) (eq? (user-name u-email) 'not-found))
          (begin (club-name club church)
                 (user-name u-email u-name)
                 (user-club u-email club)
                 (user-email u-email u-email)
                 (user-phone u-email u-phone)
                 (user-birthday u-email u-birthday)
                 (user-address u-email u-address)
                 (user-pw u-email (generate-password u-pw))
		 (user-pw-type u-email 'crypt)
                 (club-users club (cons u-email (club-users club)))
                 (send-welcome-email u-email club u-name)
		 (handle-exceptions
		  exn
		  'error
		  (send-mail from: "momentum@keeptherecords.com" from-name: "Momentum"
			     to: "momentum@keeptherecords.com" reply-to: "momentum@keeptherecords.com"
			     subject: "New Club Register!"
			    html: (++ "Good work!\n\n" u-email " just registered " church " as " club
				      " with the " plan " plan.")))
		 (redirect-to (++ "/sign-up/payment/" plan "?email=" u-email)))
          (if (eq? (user-name u-email) 'not-found)
              "Passwords don't match, please go back and re-enter your info."
              "Email already in use."))))
  method: 'POST
  no-session: #t)

;;; clubber pages

(define (clubber->url club clubber #!key (class #f))
  (<a> href: (++ "/" club "/clubbers/info/" clubber) class: (if class class "") (name club clubber)))

(define (birthday-table club clubbers)
  (<table>
   (fold (lambda (c o)
	   (++ o
	       (<tr> (<td> class: "c-cell clubber-url-cell" (clubber->url club c class: "clubber-url"))
		     (<td> class: "c-cell clubber-birthday" (birthday club c))
		     (<td> class: "c-cell clubber-club-level" (club-level club c)))))
	 ""
	 clubbers)))

(define (birthdays-within club clubbers d1 d2)
  (filter (lambda (c)
            (day/month-between? (clear-date-time (date-as-year (db->date (birthday club c))
                                                               (string->number (todays-yyyy))))
                                d1
                                d2))
          (filter (lambda (c) (db->date (birthday club c))) clubbers)))

    ;; (filter (lambda (c)
    ;;           (let* ((c-b (birthday club c))
    ;;                  (c-bd (and c-b (db->date c-b)))
    ;;                  (c-bd-c (and c-b c-bd (date-as-year (clear-date-time c-bd)
    ;;                                                      (string->number (todays-yyyy))))))
    ;;             (and c-bd-c (date>=? c-bd-c d1) (date<=? c-bd-c d2))))
    ;;         clubbers))

(define (get-birthdays-ajax club)
  (ktr-ajax club "get-birthdays" ".dt" 'change
            (lambda (club)
              (birthday-table club (birthdays-within club (db:list "clubs" club "clubbers")
                                                     (string->date ($ 'from-date)  "~m/~d/~Y")
                                                     (string->date ($ 'to-date) "~m/~d/~Y"))))
            arguments: '((from-date . "$('#from-date').val()")
                         (to-date . "$('#to-date').val()"))
            target: "birthdays"))
(get-birthdays-ajax "")

(define-awana-app-page (regexp "/[^/]*/clubbers/dashboard")
  (lambda (path)
    (let ((club (get-club path))
          (date-start (week-start (clear-date-time (current-date))))
          (date-end (week-end (clear-date-time (current-date)))))
      (add-javascript "$('#from-date').datepicker(); $('#to-date').datepicker();")
      (add-javascript (get-birthdays-ajax club))
      (++ (<div> class: "grid_12"
                 (<div> class: "column-header padding" (club-name club))
                 (<div> class: "column-body padding"
                        (folds* (lambda (t s)
                                  (++ (<a> href: (++ "/" club "/clubbers/" (string-downcase t))
                                           class: "misc-links"
                                           (<div> class: "misc-border"
                                                  (<img> src: (++ "/images/" (string-downcase t) ".png")
                                                         class: "misc-icons") s))))
                                '(("Missed" "Absent") ("Add" "Add Clubber") ("Allergies" "Allergies") ("Dues" "Dues")
                                  ("New" "First Time") ("Points" "Points")))))
          (<div> class: "clear")
          (<div> class: "grid_12"
                 (<div> class: "column-header padding" "Birthdays")
                 (<div> class: "info-header padding"
                        "From "
                        (<input> class: "dt" id: "from-date" name: "from-date"
                                 value: (date->string date-start "~m/~d/~Y"))
                        " to "
                        (<input> class: "dt" id: "to-date" name: "to-date"
                                 value: (date->string date-end "~m/~d/~Y")))
                 (<div> class: "column-body padding" id: "birthdays"
                        (birthday-table club (birthdays-within club (db:list "clubs" club "clubbers")
                                                               date-start date-end))))
          (<div> class: "clear")
          (<div> class: "grid_12"
                 (<a> href: "http://www.icons-land.com"
                      class: "cit" "Some Icons used with permission from Icons Land.")))))
  no-ajax: #f
  headers: (++ (include-javascript "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.11/jquery-ui.min.js")
               (include-javascript "/js/jquery-ui-1.8.11.custom.min.js"))
  css: '("/css/dashboard.css?ver=0" "/css/ui-lightness/jquery-ui-1.8.11.custom.css")
  tab: 'clubbers)

(define (get-club path)
  (first (string-split path "/")))

(define (grade-index grade)
  (cond ((string=? grade "age-2-or-3") 1) ((string=? grade "pre-k") 2) ((string=? grade "K") 3)
        ((string=? grade "1") 4) ((string=? grade "2") 5) ((string=? grade "3") 6) ((string=? grade "4") 7)
        ((string=? grade "5") 8) ((string=? grade "6") 9) ((string=? grade "7") 10) ((string=? grade "8") 11)
        ((string=? grade "9") 12) ((string=? grade "10") 13) ((string=? grade "11") 14) ((string=? grade "12") 15)))

(define (club-index club)
  (cond ((string=? club "Puggles") 1)
        ((string=? club "Cubbies") 2)
        ((string=? club "Sparks") 3)
        ((string=? club "TnT") 4)
        ((string=? club "Trek") 5)
        ((string=? club "Journey") 6)))

(define (escape-apostrophes string)
  (irregex-replace/all "'" string "&#39"))

(define (lookup-parent-ajax club)
  (ktr-ajax club "lookup-parent" 'parent-name-1 '(change blur)
	(lambda (club)
	  (if ($ 'p-name)
	      (map (lambda (data)
		     (cond ((string=? data "name") `(parent-name-1 . ,(parent-name club ($ 'p-name))))
			   ((string=? data "spouse") `(parent-name-2 . ,(parent-spouse club ($ 'p-name))))
			   (#t `(,(string->symbol data) .
				 ,(db:read "clubs" club "parents" ($ 'p-name) data)))))
		   (db:list "clubs" club "parents" ($ 'p-name)))
	      '()))
	success: "$.each(response, function(id, html) { $('#' + id).val(html).addClass('filled').watermark(''); })"
	update-targets: #t
	method: 'GET
	arguments: '((p-name . "parentIds[parentNames.indexOf($('#parent-name-1').val())]"))))
(lookup-parent-ajax "")

(define-awana-app-page (regexp "/[^/]*/clubbers/(add|info/[^/]*/edit)")
  (lambda (path)
    (let* ((club (get-club path))
           (edit (> (length (string-split path "/")) 3))
           (c-name (if edit (get-clubber path) #f)))
      (add-javascript (lookup-parent-ajax club))
      (++ (<div> class: "clear")
          (<div> class: "grid_12" (<div> class: "success" id: "success" (if ($ 'success) "Clubber Added Successfully" "")))
          (<div> class: "grid_6 column-header" (<div> class: "padding" "Child"))
          (<div> class: "grid_6 column-header" (<div> class: "padding" "Parent/Guardian"))
          (<div> class: "clear clear-no-space")
          (<form> action: (++ "/" club  "/clubbers/create") id: "add-clubber-form" method: 'POST
                  (if edit (hidden-input 'edit (++ "/" club "/clubbers/info/" c-name)) "")
                  (if ($ 'from) (hidden-input 'from ($ 'from)) "")
                  (<div> class: "grid_6 column-body on-top edit-clubber-box"
                         (<div> class: "padding"
                                (<table> (<tr> (<td> class: "label" (<span> class: "label-name" id: "label-name" "Name"))
                                               (<td> (<input> id: "name" class: "jq_watermark name validate[required,custom[onlyLetterSp],custom[ktr-name]]"
                                                              value: (if edit (name club c-name) "")
                                                              title: "First Last" name: "name")))
                                         (<tr> (<td> class: "label" (<span> class: "label grade" "Grade"))
                                               (<td> (combo-box "grade" '(("age-2-or-3" "Age 2 or 3")
                                                                          ("pre-k" "Pre-k") "K" "1"
                                                                          "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12")
                                                                selectedindex: (if edit (grade-index (grade club c-name)) 0)
                                                                name: "grade" class: "grade validate[required]" first-empty: #t)))
                                         (<tr> (<td> class: "label" (<span> class: "label birthday" "Birthday"))
                                               (<td> (<input> class: "jq_watermark birthday validate[custom[ktr-date]]" id: "birthday"
                                                              value: (if edit (birthday club c-name) "")
                                                              title: "mm/dd/yyyy" name: "birthday")))
                                         (<tr> (<td> class: "label" (<span> class: "label club" id: "label-club" "Club"))
                                               (<td> (combo-box "club-level"
                                                                '("Puggles" "Cubbies" "Sparks" "TnT" "Trek" "Journey")
                                                                value: (if edit (club-level club c-name) "")
                                                                selectedindex: (if edit
                                                                                   (club-index (club-level club c-name))
                                                                                   0)
                                                                name: "club-level" class: "club validate[required]" first-empty: #t)))
                                         (<tr> (<td> class: "label" (<span> class: "label allergies" "Allergies"))
                                               (<td> (<input> class: "allergies" id: "allergies" name: "allergies"
                                                              value: (if edit (allergies club c-name) ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label notes" "Notes"))
                                               (<td> (<textarea> class: "notes notes-input" id: "notes" name: "notes"
                                                              (if edit (notes club c-name) ""))))
                                         )))
                  (<div> class: "grid_6 column-body on-top edit-clubber-box"
                         (<div> class: "padding"
                                (<table> (<tr> (<td> class: "label" (<span> class: "label parent-name" "Parent Name 1"))
                                               (<td> (<input> class: "jq_watermark parent-name validate[required,custom[onlyLetterSp],custom[ktr-name]]" id: "parent-name-1"
                                                              title: "First Last" name: "parent-name-1"
                                                              value: (if edit
                                                                         (parent-name club (primary-parent club c-name))
                                                                         ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label parent-name" "Parent Name 2"))
                                               (<td> (<input> class: "jq_watermark parent-name validate[custom[onlyLetterSp],custom[ktr-name]]" id: "parent-name-2"
                                                              title: "First Last" name: "parent-name-2"
                                                              value: (if edit
                                                                         (parent-spouse club (primary-parent club c-name))
                                                                         ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label email" "Email"))
                                               (<td> (<input> class: "jq_watermark email validate[custom[email]]" id: "email"
                                                              title: "address@mail.com" name: "email"
                                                              value: (if edit
                                                                         (parent-email club (primary-parent club c-name))
                                                                         ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label phone" "Phone 1"))
                                               (<td> (<input> class: "jq_watermark phone validate[custom[ktr-phone]]" id: "phone-1"
                                                              title: "123.456.7890" name: "phone-1"
                                                              value: (if edit
                                                                         (parent-phone-1 club (primary-parent club c-name))
                                                                         ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label phone" "Phone 2"))
                                               (<td> (<input> class: "phone jq_watermark validate[custom[ktr-phone]]" id: "phone-2"
                                                              title: "123.456.7890" name: "phone-2"
                                                              value: (if edit
                                                                         (parent-phone-2 club (primary-parent club c-name))
                                                                         ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label address" "Address"))
                                               (<td> (<input> class: "jq_watermark address" id: "address"
                                                              title: "123 Food St Donut MI 49494" name: "address"
                                                              value: (if edit
                                                                         (parent-address club (primary-parent club c-name))
                                                                         ""))))
                                         (<tr> (<td> class: "label" (<span> class: "label release-to" "Release To"))
                                               (<td> (<input> class: "release-to" id: "release-to" name: "release-to"
                                                              value: (if edit
                                                                         (parent-release-to club
                                                                                            (primary-parent club c-name))
                                                                         "")))))))
                  (<div> class: "clear")
                  (<div> class: "grid_12"
                         (<div> class: "create-clubber-container"
                                (<input> type: "submit" class: "button button-blue"
                                         value: (if edit "Update" "Create")))))
          (<input> type: "hidden" id: "parent-names" value:
		   (fold (lambda (e o) (++ o "|" (escape-apostrophes (parent-name club e))))
			 "" (db:list "clubs" club "parents")))
          (<input> type: "hidden" id: "parent-ids"
		   value: (fold (lambda (e o) (++ o "|" (escape-apostrophes e)))
			 "" (db:list "clubs" club "parents"))))))
  css: '("/css/validation-engine.jquery.css" "/css/add-clubber.css?ver=1" "/css/autocomplete.css" "/css/clubbers-index.css")
  headers: (++ (include-javascript "/js/jquery.watermark.min.js")
	       (include-javascript "/js/jquery.validation-engine.js")
	       (include-javascript "/js/jquery.validation-engine-en.js")
               (include-javascript "/js/autocomplete.js")
	       (include-javascript "/js/add-clubber.js"))
  no-ajax: #f
  tab: 'clubbers
  title: "Add Clubber - Club Night - KtR")

(define (date->db date)
  (date->string date "~D"))

(define (short-year? date-string)
  (let ((s (string-split date-string "/")))
    (if (> (length s) 2)
        (if (> (string-length (third s)) 2)
            #f
            #t)
        #f)))

(define (db->date db-date)
   (handle-exceptions
    exn
    #f
    (if (short-year? db-date)
        (string->date db-date "~m/~d/~y")
        (string->date db-date "~m/~d/~Y"))))

(define-awana-app-page (regexp "/[^/]*/clubbers/create")
  (lambda (path)
    (let ((club (get-club path))
          (m-name ($ 'name))
          (from ($ 'from))
          (edit ($ 'edit)))
      (name club m-name m-name)
      (grade club m-name ($ 'grade))
      (birthday club m-name ($ 'birthday))
      (club-level club m-name ($ 'club-level))
      ; fix me
      (book club m-name (car (ad (club-level club m-name) 'book)))
      (last-section club m-name #f)
      ; end fix me
      (allergies club m-name ($ 'allergies))
      (notes club m-name ($ 'notes))
      (primary-parent club m-name ($ 'parent-name-1))
      (and (not edit) (date-registered club m-name (date->db (current-date))))
      (db:update-list (name->id m-name) "clubs" club "clubbers")
      (let ((p-name ($ 'parent-name-1)))
        (parent-name club p-name p-name)
        (parent-spouse club p-name ($ 'parent-name-2))
        (parent-email club p-name ($ 'email))
        (parent-phone-1 club p-name ($ 'phone-1))
        (parent-phone-2 club p-name ($ 'phone-2))
        (parent-address club p-name ($ 'address))
        (parent-release-to club p-name ($ 'release-to))
        (parent-children club p-name (let ((children (parent-children club p-name)))
                                       (if (eq? children 'not-found)
                                           `(,($ 'name))
                                           (cons ($ 'name) children))))
        (db:update-list "name" "clubs" club "parents" p-name)
        (db:update-list "spouse" "clubs" club "parents" p-name)
        (db:update-list "email" "clubs" club "parents" p-name)
        (db:update-list "phone-1" "clubs" club "parents" p-name)
        (db:update-list "phone-2" "clubs" club "parents" p-name)
        (db:update-list "address" "clubs" club "parents" p-name)
        (db:update-list "release" "clubs" club "parents" p-name)
        (db:update-list "children" "clubs" club "parents" p-name)
        (db:update-list (name->id p-name) "clubs" club "parents"))
      (cond (from (redirect-to from))
            (($ 'edit) (redirect-to edit))
            (#t (redirect-to (++ "/" club "/clubbers/add?success=true"))))))
  method: 'POST)

(define (present-clubbers club date)
  (filter (lambda (m-name)
            (if (present club m-name date) #t #f)) (db:list "clubs" club "clubbers")))

(define (attendees-html club date)
  (let ((present-clubbers (sort (present-clubbers club date) string<)))
    (++ "In Attendance: "
        (number->string (fold (lambda (m c) (+ c 1)) 0 present-clubbers))
        (<br>) (<br>)
        (fold (lambda (m-name o)
                (++ o (<a> href: (++ "/" club "/clubbers/info/" (html-escape m-name)) (html-escape (name club m-name))) (<br>)))
              ""
              present-clubbers))))

;;; attendance

(define (clubber-attendance-info-ajax club)
  (ktr-ajax club "clubber-attendance-info" ".select-clubber-name" 'click
            (lambda (club)
              (let ((n ($ 'name))
		    (date (++ (or ($ 'year) (todays-yyyy)) "/" (or ($ 'month) (todays-mm)) "/" (or ($ 'day) (todays-dd)))))
                (if n
                    `((clubber-name . ,(name club n))
                      (present . ,(present club n date))
                      (bible . ,(bible club n date))
                      (handbook . ,(handbook club n date))
                      (uniform . ,(uniform club n date))
                      (friend . ,(friend club n date))
                      (extra . ,(extra club n date))
                      (sunday-school . ,(sunday-school club n date))
                      (dues . ,(dues club n date))
                      (on-time . ,(on-time club n date))
                      (points-total . ,(total-points club n))
                      (allergies . ,(allergies club n))
                      (club-level . ,(club-level club n))
                      (notes . ,(notes club n))
                      (attendees-html . ,(attendees-html club date)))
                    '())))
            success: "loadClubberInfo(response);"
            update-targets: #t
            method: 'GET
            arguments: '((name . "$('li.selected').attr('id')") (month . "month") (day . "day") (year . "year"))))
(clubber-attendance-info-ajax "")

(define (save-clubber-attendance-info club proc id)
  (ktr-ajax club (++ "save-" (symbol->string id)) id 'click
	(lambda (club)
	  (proc club ($ 'name)
		(++ (or ($ 'year) (todays-yyyy)) "/" (or ($ 'month) (todays-mm)) "/" (or ($ 'day) (todays-dd)))
		(if (string=? ($ id) "false") #f #t))
          ($ 'requestid))
        success: "clearSaving(response);"
	method: 'PUT
        prelude: (++ "setSaving('" (symbol->string id) "');")
	arguments: `((name . "$('li.selected').attr('id')") (,id . ,(++ "stringToBoolean($('#" (symbol->string id) "').val())"))
		      (month . "month") (day . "day") (year . "year") (requestid . ,(++ "requestId('" (symbol->string id) "')")))))

(map (lambda (l) (save-clubber-attendance-info "" (car l) (cadr l)))
     `((,present present) (,bible bible) (,uniform uniform) (,friend friend) (,extra extra) (,sunday-school sunday-school)
       (,dues dues) (,on-time on-time) (,handbook handbook)))

(define (save-note-attendance-info club)
  (ktr-ajax club "save-attendance-note" 'notes 'change
            (lambda (club)
              (notes club ($ 'name) ($ 'note)))
            method: 'PUT
            arguments: `((name . "$('li.selected').attr('id')") (note . "$('#notes').val()"))))
(save-note-attendance-info "")

(define-awana-app-page (regexp "/[^/]*/clubbers/attendance")
  (lambda (path)
    (let ((club (get-club path)))
      (add-javascript (clubber-attendance-info-ajax club))
      (add-javascript (++ "var month = '" (or ($ 'month) (todays-mm)) "'; var day = '"
			                            (or ($ 'day) (todays-dd)) "'; var year = '" (or ($ 'year) (todays-yyyy)) "';"))
      (add-javascript (save-note-attendance-info club))
      (map (lambda (l)
	     (add-javascript (save-clubber-attendance-info club (car l) (cadr l))))
	   `((,present present) (,bible bible) (,uniform uniform) (,friend friend) (,extra extra) (,sunday-school sunday-school)
	     (,dues dues) (,on-time on-time) (,handbook handbook)))
      (++ (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (<form> action: path  method: "GET"
                                (<span> class: "date-label" "Date:")
                                (<input> class: "date-input" name: "month" id: "month"
                                         value: (or ($ 'month) (todays-mm))) "/"
                                (<input> class: "date-input" name: "day" id: "day"
                                         value: (or ($ 'day) (todays-dd))) "/"
                                (<input> class: "date-input" name: "year" id: "year"
                                         value: (or ($ 'year) (todays-yyyy)))
                                (<a> href: (++ path "?month=" (todays-mm) "&day=" (todays-dd) "&year=" (todays-yyyy))
                                     class: "preset-date" "Today")
                                ;(<a> href: "#" class: "preset-date" "Last Club Meeting")
                                (<input> class: "change-date" type: "submit" value: "Update Date"))))
          (<div> class: "clear")
          (<div> class: "grid_3 column-header" (<div> class: "padding" "Find Clubbers"))
          (<div> class: "grid_6 column-header" id: "clubber-name-container"
                 (<div> id: "clubber-name" class: "padding" "Mark Attendance"))
          (<div> class: "grid_3 column-header" (<div> class: "padding" "Attendees"))
          (<div> class: "grid_3 column-body"
                 (<div> class: "padding"
                        (<input> type: "text" class: "jq_watermark filter" title: "search" id: "filter")
			(<ul> id: "clubber-names" class: "clubbers"
			      (fold (lambda (e o)
				      (++ o (<li> class: "select-clubber-name" id: (html-escape e) (html-escape (name club e)))))
				    ""
				    (name-sort club (db:list "clubs" club "clubbers") "last")))))
          (<div> class: "grid_6 column-body"
                 (<div> class: "padding"
                        (<div> class: "description-container" id: "description-container"
                                      "To begin, click on a name to the left" (<br>) (<br>)
                                      "<--" (<br>) (<br>)
                                      "You can also filter (sort of like search) the names by typing into the box above the clubbers")
                        (<div> class: "clubber-data" id: "clubber-data"
                               (<div> class: "attendance-container"
                                      (fold (lambda (e o)
                                              (++ o (<div> class: "attendance-button" id: (car e) (cadr e)
                                                           (<input> class: (car e) type: "button" value: "")
                                                           (<div> class: "attendance-saving-notifier" id: (++ "saving-notifier-" (car e))
                                                                  "saving"))))
                                            ""
                                            '(("present" "Present") ("bible" "Bible") ("handbook" "Handbook") ("uniform" "Uniform")
                                              ("friend" "Friend") ("extra" "Extra") ("sunday-school" "Sunday") ("on-time" "On Time"))))
                               (<div> class: "points-container"
                                      (<div> class: "points" id: "points-total")
                                      (<div> class: "points points-label" " points"))
                               (<div> class: "allergy-info" id: "allergy-container"
                                      (<div> class: "allergic-to info" "Allergic To:") (<br>)
                                      (<div> class: "allergic-to-item" id: "allergies" ""))
                               (<div> class: "clear")
                               (<div> class: "notes-header" "Notes")
                               (<textarea> class: "notes info" id: "notes"))))
          (<div> class: "grid_3 column-body"
              (<div> class: "tab-body padding"
                     (<div> class: "attendees" id: "attendees"
                            (attendees-html club (++ (or ($ 'year) (todays-yyyy)) "/"
						     (or ($ 'month) (todays-mm)) "/"
						     (or ($ 'day) (todays-dd))))))))))
  headers: (++ (include-javascript "/js/attendance.js?ver=5")
	       (include-javascript "/js/jquery.watermark.min.js")
	       (include-javascript "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/jquery-ui.min.js"))
  no-ajax: #f
  css: '("/css/attendance.css?ver=8" "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.23/themes/ui-lightness/jquery-ui.css")
  tab: 'clubbers
  title: "Attendance - Club Night -KtR")

;;; clubbers

(define (search-filter club clubbers search)
  (if search
      (filter (lambda (e) (string-contains-ci (name club e) search)) clubbers)
      clubbers))

(define (club-filter club clubbers c-level)
  (filter (lambda (e) (if (string-ci=? (club-level club e) c-level) #t #f)) clubbers))

(define (name-sort club clubbers sort-value)
  (sort clubbers (lambda (e1 e2)
                   (if (and sort-value (string=? sort-value "last"))
                       (let ((n1 (string-split e1 "-"))
                             (n2 (string-split e2 "-")))
			 (string< (++ (if (> (length n1) 1) (second n1) "") "-" (first n1))
				  (++ (if (> (length n2) 1) (second n2) "") "-" (first n2))))
                       (string< e1 e2)))))

(define (clubbers->names club clubbers)
  (map (lambda (clubber)
         (name club clubber))
       clubbers))

(define (clubbers->urls club clubbers first-name-first)
  (fold (lambda (e o)
          (++ o (<a> class: "clubber-url" href: (++ "/" club "/clubbers/info/" e)
                     (++ (if first-name-first
                             (name club e)
                             (++ (second (string-split (name club e) " ")) " "
                                 (first (string-split (name club e) " "))))
                         (<br>)))))
        ""
        clubbers))

(define-awana-app-page (regexp "/[^/]*/clubbers/find")
  (lambda (path)
    (let ((club (get-club path))
          (search ($ 'search))
          (sort-value ($ 'sort)))
      (++ (<div> class: "clear")
          (<div> class: "grid_12 column-body"
                 (<table>
                  (<tr>
                   class: "opts-row"
                   (<td> class: "opts padding"
                         (<form> action: path method: "GET"
                                 "Search: "
                                 (<input> type: "text" id: "search" name: "search" class: "search"
                                          value: (if search search ""))))
                   (<td> class: "opts padding"
                         "Sort By"
                         (<a> href: (++ path "?sort=first" (if search (++ "&search=" search) ""))
                              class: (++ "sort-link"
                                         (if (or (not sort-value) (and sort-value (string=? sort-value "first")))
                                             " current-sort" "")) "First Name")
                         (<a> href: (++ path "?sort=last" (if search (++ "&search=" search) ""))
                              class: (++ "sort-link"
                                         (if (and sort-value (string=? sort-value "last"))
                                             " current-sort" "")) "Last Name"))
                   (<td> class: "opts padding"
                         (<span> class: "new-clubber-symbol" "+ ")
                         (<a> href: (++ "/" club "/clubbers/add") class: "new-clubber" "Add New Clubber")))))
          (<div> class: "clear")
          (let* ((clubbers (name-sort club (search-filter club (db:list "clubs" club "clubbers") ($ 'search)) sort-value))
                 (sort-by-first (if (and ($ 'sort) (string=? ($ 'sort) "last")) #f #t))
                 (puggles (club-filter club clubbers "puggles"))
                 (cubbies (club-filter club clubbers "cubbies"))
                 (sparks (club-filter club clubbers "sparks"))
                 (tnt (club-filter club clubbers "tnt"))
                 (trek (club-filter club clubbers "trek"))
                 (journey (club-filter club clubbers "journey")))
            (++ (if (> (length puggles) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Puggles")) "")
                (if (> (length cubbies) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Cubbies")) "")
                (if (> (length sparks) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Sparks")) "")
                (if (> (length tnt) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "TnT")) "")
                (if (> (length trek) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Trek")) "")
                (if (> (length journey) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Journey")) "")
                (<div> class: "clear clear-no-space")
		(if (> (length puggles) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length puggles)) " clubbers")) "")
                (if (> (length cubbies) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length cubbies)) " clubbers")) "")
                (if (> (length sparks) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length sparks)) " clubbers")) "")
                (if (> (length tnt) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length tnt)) " clubbers")) "")
                (if (> (length trek) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length trek)) " clubbers")) "")
                (if (> (length journey) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length journey)) " clubbers")) "")
                (<div> class: "clear clear-no-space")
                (if (> (length puggles) 0) (<div> class: "grid_2 column-body"
                                                  (<div> class: "padding"
                                                         (clubbers->urls club puggles sort-by-first))) "")
                (if (> (length cubbies) 0) (<div> class: "grid_2 column-body"
                                                  (<div> class: "padding"
                                                         (clubbers->urls club cubbies sort-by-first))) "")
                (if (> (length sparks) 0) (<div> class: "grid_2 column-body"
                                                 (<div> class: "padding"
                                                        (clubbers->urls club sparks sort-by-first))) "")
                (if (> (length tnt) 0) (<div> class: "grid_2 column-body"
                                              (<div> class: "padding"
                                                     (clubbers->urls club tnt sort-by-first))) "")
                (if (> (length trek) 0) (<div> class: "grid_2 column-body"
                                               (<div> class: "padding"
                                                      (clubbers->urls club trek sort-by-first))) "")
                (if (> (length journey) 0) (<div> class: "grid_2 column-body"
                                                  (<div> class: "padding"
                                                         (clubbers->urls club journey sort-by-first))) "")
                (<div> class: "clear")
                (if (> (length clubbers) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "All Clubs")) "")
                (<div> class: "clear clear-no-space")
                (if (> (length clubbers) 0) (<div> class: "grid_2 info-header" (<div> class: "padding" (number->string (length clubbers)) " clubbers")) "")
                (<div> class: "clear clear-no-space")
                (if (> (length clubbers) 0) (<div> class: "grid_2 column-body"
                                                   (<div> class: "padding"
                                                          (clubbers->urls club clubbers sort-by-first))) ""))))))
  css: '("/css/clubbers-index.css")
  tab: 'clubbers
  title: "Clubbers - Club Night - KtR")

(define (start-of-season date)
    (if (> (date-month date) 6)
	      (make-date 0 0 0 0 1 6 (date-year date))
	            (make-date 0 0 0 0 1 6 (- (date-year date) 1))))

(define (end-of-season date)
    (if (> (date-month date) 6)
	      (make-date 0 0 0 0 1 6 (+ (date-year date) 1))
	            (make-date 0 0 0 0 1 6 (date-year date))))

(define (current-season? date)
    (and date (date>=? date (start-of-season (current-date)))
	        (date<=? date (end-of-season (current-date)))))

(define (get-clubber path)
  (fourth (string-split path "/")))

(define (list-years club clubber)
  (db:list "clubs" club "clubbers" clubber "attendance"))

(define (list-months club clubber year)
  (db:list "clubs" club "clubbers" clubber "attendance" year))

(define (list-days club clubber year month)
  (db:list "clubs" club "clubbers" clubber "attendance" year month))

(define (attendance-dates club clubber)
  (if (> (length (db:list "clubs" club "clubbers" clubber "attendance")) 0)
      (concatenate (concatenate (map (lambda (year)
                                       (map (lambda (month)
					      (map (lambda (day)
                                                     (list month day year))
                                                   (sort 
						    (filter
						     (lambda (day)
						       (current-season? (db->date (++ month "/" day "/" year))))
						     (list-days club clubber year month))
						    string<)))
					      (sort (list-months club clubber year) string<)))
				       (sort (list-years club clubber) string<))))
		   '()))

(define (dates->filled-tds proc club clubber dates)
  (fold (lambda (date-l o)
          (++ o (<td> (<div> class:
                             (if (proc club clubber (++ (third date-l) "/" (first date-l) "/" (second date-l)))
                                 "fill" "") "X"))))
        ""
        dates))

(define (delete-clubber-ajax club clubber)
  (++ "clubber = '" clubber "';"
      (ktr-ajax club "delete-clubber" 'delete-clubber 'click
		(lambda (club)
		  (db:remove-from-list ($ 'clubber) "clubs" club "clubbers"))
		arguments: '((clubber . "clubber"))
		success: "$('#restore-clubber').show(); $('#delete-clubber').hide();")))
(delete-clubber-ajax "" "")

(define (restore-clubber-ajax club clubber)
  (++ "clubber = '" clubber "';"
      (ktr-ajax club "restore-clubber" 'restore-clubber 'click
		(lambda (club)
		  (db:update-list ($ 'clubber) "clubs" club "clubbers"))
		arguments: '((clubber . "clubber"))
		success: "$('#restore-clubber').hide(); $('#delete-clubber').show();")))
(restore-clubber-ajax "" "")

(define-awana-app-page (regexp "/[^/]*/clubbers/info/[^/]*")
  (lambda (path)
    (let* ((clubber (get-clubber path))
           (club (get-club path))
           (p-parent (primary-parent club clubber))
           (dates (attendance-dates club clubber)))
      (add-javascript (delete-clubber-ajax club clubber))
      (add-javascript (restore-clubber-ajax club clubber))
      (++ (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (<a> href: (++ path "/edit") class: "edit" "Edit this clubber")
			" - "
			(<a> href: "#self" class: "edit delete" id: "delete-clubber" "Delete this clubber")
			(<a> href: "#self" style: "display: none;" class: "edit restore" id: "restore-clubber" "Restore this clubber (un-delete)")))
          (<div> class: "clear")
          (<div> class: "grid_12" (<div> class: "column-header padding" (name club clubber)))
          (<div> class: "grid_12 column-body"
                 (<div> class: "grid_8 no-margins"
                        (<div> class: "grid_2 margins-right" (<div> class: "info-header padding" "General Info"))
                        (<div> class: "grid_2 margins-right" (<div> class: "info-header padding" "Allergies"))
                        (<div> class: "grid_2 no-margins" (<div> class: "info-header padding" "Release To"))
                        (<div> class: "clear clear-no-space")
                        (<div> class: "grid_2 margins-right"
                               (<div> class: "padding info-body"
                                      (club-level club clubber) (<br>)
                                      "Grade: " (id->name (grade club clubber)) (<br>)
                                      (birthday club clubber) (<br>)
                                      (total-points club clubber) " points" (<br>) (<br>)
                                      "Registered: " (date-registered club clubber)))
                        (<div> class: "grid_2 margins-right info-body"
                               (<div> class: "padding"
                                      (let ((a (allergies club clubber)))
                                        (if (or (string=? a "") (string-ci=? a "none"))
                                            ""
                                            a))))
                        (<div> class: "grid_2 no-margins info-body"
                               (<div> class: "padding"
                                      (parent-release-to club p-parent))))
                 (<div> class: "grid_4 no-margins"
                        (<div> class: "grid_4 margins-left" (<div> class: "info-header padding" "Parents"))
                        (<div> class: "grid_4 margins-left"
                               (<div> class: "padding info-body parent-info"
                                      (<a> class: "parent-name" href: (++ "/" club "/parents/" (name->id p-parent))
                                           (parent-name club p-parent))
                                      ", "
                                      (<a> class: "parent-name" href: (++ "/" club "/parents/" (name->id p-parent))
                                           (parent-spouse club p-parent))
                                      (<br>) (<br>)
                                      (<span> class: "phone" (parent-phone-1 club p-parent)) " "
                                      (<span> class: "phone" (parent-phone-2 club p-parent))
                                      (<br>)
                                      (<span> class: "email" (<a> href: (++ "mailto:" (parent-email club p-parent))
                                                                  (parent-email club p-parent)))
                                      (<br>)
                                      (<span> class: "address" (parent-address club p-parent)))))
                 (<div> class: "grid_12 no-margins"
                        (<div> class: "grid_12 no-margins" (<div> class: "info-header padding" "Attendance"))
                        (<div> class: "grid_12 no-margins"
                               (<div> class: "padding info-body"
                                      (<table> class: "attendance"
                                               (++ (<tr> (<td> class: "label" "Date")
                                                         (fold (lambda (e o)
                                                                 (++ o (<td> class: "label"
                                                                             (++ (first e) "/" (second e)))))
                                                               ""
                                                               dates))
                                                   (fold (lambda (e o)
                                                           (++ o (<tr> (<td> class: "label" (first e))
                                                                       (dates->filled-tds (second e) club clubber dates))))
                                                         ""
                                                         `(("Present" ,(lambda (c cl d) (present c cl d)))
                                                           ("Bible" ,(lambda (c cl d) (bible c cl d)))
                                                           ("Handbook" ,(lambda (c cl d) (handbook c cl d)))
                                                           ("Uniform" ,(lambda (c cl d) (uniform c cl d)))
                                                           ("Friend" ,(lambda (c cl d) (friend c cl d)))
                                                           ("Extra" ,(lambda (c cl d) (extra c cl d)))
                                                           ("Sunday School" ,(lambda (c cl d) (sunday-school c cl d)))
                                                           ("Dues" ,(lambda (c cl d) (dues c cl d)))
                                                           ("On Time" ,(lambda (c cl d) (on-time c cl d))))))))))
                 (<div> class: "grid_4 no-margins"
                        (<div> class: "grid_4 margin-right" (<div> class: "info-header padding" "Notes"))
                        (<div> class: "clear clear-no-space")
                        (<div> class: "grid_4 margins-right"
                               (<div> class: "padding info-body" (notes club clubber))))
                 ))))
  css: '("/css/clubbers.css?ver=2")
  tab: 'clubbers
  no-ajax: #f
  title: "Clubber Info - Club Night - KtR")

(define (false->date e) (if (not e) (make-date 0 0 0 0 9 9 1999) e))

(define (make-registration-sort club)
  (lambda (c1 c2)
    (date<? (false->date (db->date (date-registered club c2)))
            (false->date (db->date (date-registered club c1))))))

(define-awana-app-page (regexp "/[^/]*/clubbers/new")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12 column-header"
                 (<div> class: "padding" "Clubbers By Registration Date"))
          (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (<table>
                         (<tr> (<td> class: "col-head" "Clubber")
                               (<td> class: "col-head" "Registered")
                               (<td> class: "col-head" "Sent Thank You?")
                               (<td> class: "col-head" "Address"))
                         (fold (lambda (c o)
                                 (ajax (++ "update-thank-you-" club (js-filter c))
                                       (string->symbol (++ "thank-you" (js-filter c)))
                                       'click
                                       (lambda ()
                                         (thank-you club c (date->db (current-date)))
                                         (date->db (current-date)))
                                       target: (++ "thank-you" (js-filter c))
                                       method: 'PUT)
                                 (++ o
                                     (<tr> (<td> (<a> href: (++ "/" club "/clubbers/info/" c)
                                                      class: "clubber-name"
                                                      (name club c)))
                                           (<td> (date-registered club c))
                                           (<td> (let ((t (thank-you club c)))
                                                   (if t
                                                       (<div> class: "yes" t)
                                                       (<div> class: "no" id: (++ "thank-you" (js-filter c)) "No"))))
                                           (<td> (parent-address club (primary-parent club c))))))
                               ""
                               (sort (db:list "clubs" club "clubbers") (make-registration-sort club)))))))))
  no-ajax: #f
  tab: 'clubbers
  css: '("/css/clubbers-index.css?ver=2" "/css/clubbers-new.css?ver=0")
  title: "New Clubbers - Club Night - KtR")

(define (string->date> sd1 sd2)
  (date>? (string->date sd1 "~Y/~m/~d") (string->date sd2 "~Y/~m/~d")))

(define (last-club-meetings club num)
  (let ((cm (club-meetings club)))
    (take (sort (map (lambda (m) (car m)) (club-meetings club)) string->date>)
          (if (< (length cm) num)
              (length cm)
              num))))

(define (missed-clubs? club clubber club-meetings)
  (fold (lambda (meeting missed)
          (if missed
              (not (present club clubber meeting))
              #f))
        #t
        club-meetings))

(define-awana-app-page (regexp "/[^/]*/clubbers/missed")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12 column-header"
                 (<div> class: "padding" "Clubbers who missed the last three club meetings"))
          (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (let ((c-meetings (last-club-meetings club 3)))
                          (<table>
                           (<tr> (<td> class: "col-head" "Clubber")
                                 (<td> class: "col-head" "Sent Miss You Card?"))
                           (fold (lambda (e o)
                                   (ajax (++ "update-miss-you-" club (js-filter e))
                                         (string->symbol (++ "miss-you" (js-filter e)))
                                         'click
                                         (lambda ()
                                           (miss-you club e (date->db (current-date)))
                                           (date->db (current-date)))
                                         target: (++ "miss-you" (js-filter e))
                                         method: 'PUT)
                                   (++ o
                                       (if (missed-clubs? club e c-meetings)
                                           (<tr> (<td> (<a> href: (++ "/" club "/clubbers/info/" e)
                                                            class: "clubber-url" (name club e)))
                                                 (<td> (let ((t (miss-you club e)))
                                                         (if t
                                                             (<div> class: "yes" t)
                                                             (<div> class: "no" id: (++ "miss-you" (js-filter e)) "No")))))
                                           "")))
                                 ""
                                 (db:list "clubs" club "clubbers")))))))))
  no-ajax: #f
  tab: 'clubbers
  css: '("/css/clubbers-index.css?ver=2" "/css/clubbers-new.css?ver0")
  title: "Clubbers Missed - Club Night - KtR")

(define-awana-app-page (regexp "/[^/]*/clubbers/dues")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12 column-header"
                 (<div> class: "padding" "Dues"))
          (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (<table>
                         (<tr> (<td> class: "col-head" "Clubber")
                               (<td> class: "col-head" "Receipt Number"))
                         (fold (lambda (e o)
                                 (ajax (++ "dues-receipt-" club (js-filter e))
                                       (string->symbol (++ "dues-receipt" (js-filter e)))
                                       'change
                                       (lambda ()
                                         (dues-receipt club e ($ 'dues-receipt)))
                                       arguments: `((dues-receipt . ,(++ "$('#dues-receipt" (js-filter e) "').val()")))
                                       method: 'PUT)
                                 (++ o
                                     (<tr> (<td> (<a> href: (++ "/" club "/clubbers/info/" e)
                                                      class: "clubber-url" (name club e)))
                                           (<td> (let ((t (dues-receipt club e)))
                                                   (if t
                                                       (<input> class: "yes" id: (++ "dues-receipt" (js-filter e)) value: t)
                                                       (<input> class: "no" id: (++ "dues-receipt" (js-filter e)))))))
                                     ""))
                               ""
                               (name-sort club (db:list "clubs" club "clubbers") "last"))))))))
  no-ajax: #f
  tab: 'clubbers
  css: '("/css/clubbers-index.css?ver=2" "/css/clubbers-dues.css?ver=0")
  title: "Dues - Club Night - KtR")

(define-awana-app-page (regexp "/[^/]*/clubbers/points")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12" (<div> class: "padding column-header" "Clubber Points"))
          (<div> class: "grid_12"
                 (<div> class: "padding column-body"
                        (<table>
                         (fold (lambda (c o)
                                 (++ o
                                     (<tr> class: "clubber-row"
                                           (<td> class: "name-cell"
                                                 (<a> class: "clubber-name"
                                                      href: (++ "/" club "/clubbers/info/" c) (name club c)))
                                           (<td> class: "aux-cell" (total-points club c)))))
                               ""
                               (sort (db:list "clubs" club "clubbers")
                                     (lambda (c1 c2)
                                       (< (total-points club c2)
                                          (total-points club c1)))))))))))
  css: '("/css/key-value.css?ver=1" "/css/clubbers-index.css?ver=2")
  title: "Points - Club Night - KtR"
  tab: 'clubbers)

;;; watch list

(define (allergy-filter club clubbers)
  (filter (lambda (e) (if (not (string=? (allergies club e) "")) #t #f)) clubbers))

(define (clubbers->allergy-box club clubbers first-name-first)
  (fold (lambda (e o)
          (++ o
              (<a> class: "clubber-url" href: (++ "/" club "/clubbers/info/" e)
                   (if first-name-first
                       (name club e)
                       (++ (second (string-split (name club e) " ")) " "
                           (first (string-split (name club e) " ")))))
              (<br>)
              (<div> class: "allergies" (allergies club e))
              (<br>)))
        ""
        clubbers))

(define-awana-app-page (regexp "/[^/]*/clubbers/allergies")
  (lambda (path)
      (++ (let* ((club (get-club path))
                 (clubbers (allergy-filter club (db:list "clubs" club "clubbers")))
                 (sort-by-first #t)
                 (puggles (club-filter club clubbers "puggles"))
                 (cubbies (club-filter club clubbers "cubbies"))
                 (sparks (club-filter club clubbers "sparks"))
                 (tnt (club-filter club clubbers "tnt"))
                 (trek (club-filter club clubbers "trek"))
                 (journey (club-filter club clubbers "journey")))
            (++ (<div> class: "grid_12")
                (if (> (length puggles) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Puggles")) "")
                (if (> (length cubbies) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Cubbies")) "")
                (if (> (length sparks) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Sparks")) "")
                (if (> (length tnt) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "TnT")) "")
                (if (> (length trek) 0) (<div> class: "grid_2 column-header" (<div> class: "padding" "Trek")) "")
                (if (> (length journey) 0) (<div> class: "grid_2 column-header" (<div> class: "Journey")) "")
                (<div> class: "clear clear-no-space")
                (if (> (length puggles) 0) (<div> class: "grid_2 column-body"
                                                  (<div> class: "padding"
                                                         (clubbers->allergy-box club puggles sort-by-first))) "")
                (if (> (length cubbies) 0) (<div> class: "grid_2 column-body"
                                                  (<div> class: "padding"
                                                         (clubbers->allergy-box club cubbies sort-by-first))) "")
                (if (> (length sparks) 0) (<div> class: "grid_2 column-body"
                                                 (<div> class: "padding"
                                                        (clubbers->allergy-box club sparks sort-by-first))) "")
                (if (> (length tnt) 0) (<div> class: "grid_2 column-body"
                                              (<div> class: "padding"
                                                     (clubbers->allergy-box club tnt sort-by-first))) "")
                (if (> (length trek) 0) (<div> class: "grid_2 column-body"
                                               (<div> class: "padding"
                                                      (clubbers->allergy-box club trek sort-by-first))) "")
                (if (> (length journey) 0) (<div> class: "grid_2 column-body"
                                                  (<div> class: "padding"
                                                         (clubbers->allergy-box club journey sort-by-first))) "")))))
  css: '("/css/watch-list.css")
  tab: 'clubbers
  title: "Allergies - Club Night - KtR")

;;; discharge

(define (reverse-name name)
  (let ((n (string-split name " ")))
    (++ (second n) " " (first n))))

(define-page (regexp "/[^/]*/clubbers/release/awana-release-form")
  (lambda (path)
    (let ((club (get-club path)))
      (define-pdf (++ "/" club "/clubbers/release/awana-release-form-" club "-"
                      (date->string (current-date) "~m~d~y") ".pdf")
        (lambda ()
          (pdf-release-form (map reverse-name (clubbers->names club (name-sort club (present-clubbers club (todays-date)) "last")))
                            (++ club "-awana-release-form.pdf"))
          (insert-file (++ club "-awana-release-form.pdf"))))
      (redirect-to (++ "/" club "/clubbers/release/awana-release-form-" club "-"
                       (date->string (current-date) "~m~d~y") ".pdf")))))

(define-awana-app-page (regexp "/[^/]*/clubbers/release")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12 column-body" (<div> class: "padding"
                                                     (<a> href: (++ "/" club "/clubbers/release/awana-release-form")
                                                          class: "sig-link"
                                                          "Print Signature Release Form")
                                                     (<span> class: "sig-info"
                                                             "Used if you need parent signatures to release children (generated based on today's attendance)")))
          (<div> class: "clear")
          (<div> class: "grid_6 column-header" (<div> class: "padding" "By Child"))
          (<div> class: "grid_6 column-header" (<div> class: "padding" "By Guardian"))
          (<div> class: "grid_6 column-body"
                 (<div> class: "padding"
                        (fold (lambda (clubber-pair o)
                                (++ o
                                    (<a> class: "name" href: (++ "/" club "/clubbers/clubbers/info/" (fourth clubber-pair))
                                         (++ (first clubber-pair) " " (second clubber-pair)))
                                    " - "
                                    (parent-release-to club (primary-parent club (third clubber-pair))) (<br>)))
                              ""
                              (sort (map (lambda (e)
                                           (let* ((n (name club e))
                                                  (s (string-split n " ")))
                                             (list (second s) (first s) n e)))
                                         (db:list "clubs" club "clubbers"))
                                    (lambda (e1 e2)
                                      (string< (first e1) (first e2)))))))
          (<div> class: "grid_6 column-body" (<div> class: "padding" "Coming soon!")))))
  css: '("/css/release.css")
  tab: 'clubbers
  title: "Release - Club Night - KtR")

;;; sections

(define (disp-date d)
  (if d
      d
      ""))

(define (chapter-from chapters/sections chapter)
  (if (or (empty? chapters/sections) (string=? (car (car chapters/sections)) chapter))
      chapters/sections
      (chapter-from (cdr chapters/sections) chapter)))

(define (section-from section-list section)
  (if (or (empty? section-list) (string=? (car section-list) section))
      (if (empty? section-list) '() (cdr section-list))
      (section-from (cdr section-list) section)))

(define (next-section-pruned chapters/sections club clubber club-level book)
  (if (empty? chapters/sections)
      chapters/sections
      (if (empty? (cadar chapters/sections))
	  (next-section-pruned (cdr chapters/sections) club clubber club-level book)
	  (if (not (string=? (clubber-section club clubber club-level book (caar chapters/sections) (caadar chapters/sections)) ""))
	      (next-section-pruned (cons (cons (caar chapters/sections) (list (cdadar chapters/sections))) (cdr chapters/sections)) ; remove current section
			    club clubber club-level book)
	      (list club-level book (caar chapters/sections) (caadar chapters/sections))))))

(define (prune-till-section club clubber club-level book chapter section)
  (let ((chapters/sections (chapter-from (ad club-level book 'chapter 'section) chapter)))
    (cons (cons (caar chapters/sections) (list (section-from (cadar chapters/sections) section))) (cdr chapters/sections))))

(define (next-section club clubber club-level book chapter section)
  (next-section-pruned (prune-till-section club clubber club-level book chapter section) club clubber club-level book))

(define (->html-id s)
  (string-fold
   (lambda (c o)
     (++ o
	 (cond ((char=? #\space c) "-")
	       ((char=? #\: c) "")
	       (#t (->string c)))))
   "" s))

(define (clubber-books-ajax club)
  (ktr-ajax club "clubber-books" 'clubbers '(change keypress)
	    (lambda (club)
              ;;; FIX ME need to map/reduce db for consistency
              ; this resets inconsistent book/club combos to default
              ; club book
              (when (null-list? (let ((book (book club ($ 'clubber))))
                            (filter (lambda (e) (equal? e book))
                                    (ad (club-level club ($ 'clubber)) 'book))))
                    (book club ($ 'clubber) (car (ad (club-level club ($ 'clubber)) 'book)))
                    (last-section club ($ 'clubber) #f))
              (book club ($ 'clubber))
	      (combo-box "change-book" (ad (club-level club ($ 'clubber)) 'book)
			 selectedindex: (book-index club ($ 'clubber)) class: "change-book"
			 default: (book club ($ 'clubber))))
	    success: "$('#info-header').html(response); $('#change-book').attr('selectedIndex', $('#change-book').attr('selectedindex'));"
	    arguments: '((clubber . "$('#clubbers').val()[0]"))
	    live: #t
	    method: 'GET
	    target: "info-header"))
(clubber-books-ajax "")

(define (clubber-sections-ajax club)
  (ktr-ajax club "clubber-sections" "#change-book, #clubbers" '(change keypress)
	    (lambda (club)
	      (if (string=? ($ 'book "false") "false") #f (book club ($ 'clubber) ($ 'book)))
	      (if (string=? ($ 'book-index "false") "false") #f (book-index club ($ 'clubber) ($ 'book-index)))
	      (if (string=? (book club ($ 'clubber)) "") (book club ($ 'clubber) (first (ad (club-level club ($ 'clubber)) 'b))) #f)
	      (let* ((clubber ($ 'clubber))
		     (last (last-section club clubber))
		     (next (if last (next-section club clubber (first last) (second last) (third last) (fourth last)) #f))
		     (chapter (if next (if (> (length next) 2) (third next) #f) (first (ad (club-level club clubber) (book club clubber) 'chapter))))
		     (section (if next (if (> (length next) 2) (fourth next) #f) (caadar (ad (club-level club clubber) (book club clubber) 'chapter 'section)))))
		`((sections .
			    ,(fold (lambda (chapter/sections o)
				     (++ o (<span> class: "chapter" (first chapter/sections))
					 " "
					 (fold (lambda (s o)
						 (let ((c-section (clubber-section club ($ 'clubber) (club-level club ($ 'clubber))
										   (book club ($ 'clubber)) (first chapter/sections) (->string s))))
						   (++ o (<button> type: "button"
								   class: (++ "mark-section" (if (string=? c-section "") "" " done"))
								   value: (++ (->string s) "|" (first chapter/sections))
								   id: (->html-id (++ (first chapter/sections) "-" s))
					; no dates for now
					;(if (string=? c-section "")
					;    (->string s)
					;    c-section)
								   s
								   (hidden-input 'chapter (first chapter/sections)))
						       " ")))
					       "" (second chapter/sections))
					 (<br>)))
				   ""
				   (ad (club-level club ($ 'clubber)) (book club ($ 'clubber)) 'chapter 'section)))
		  (mark-id . ,(if (and chapter section) (->html-id (++ chapter "-" section)) ""))
		  (mark-text . ,(if (and chapter section) (++ chapter " - " section) "")))))
	    update-targets: #t
	    arguments: '((clubber . "$('#clubbers').val()[0]")
			 (book . "(function () { if (event.target.id != 'clubbers') { return $('#change-book').val(); } return 'false'; })()")
			 (book-index . "(function () { if (event.target.id != 'clubbers') { return $('#change-book').attr('selectedIndex'); } return 'false'; })()"))
	    success: "$('#sections-container').html(response['sections']);
                      $('#easy-mark').unbind('click').bind('click', function () { $('#' + response['mark-id']).click(); }).text(response['mark-text']);"
	    method: 'GET
	    live: #t))
(clubber-sections-ajax "")

(define (mark-section-ajax club)
  (ktr-ajax club "mark-section" ".mark-section" 'click
	    (lambda (club)
	      (let ((c-section (clubber-section club ($ 'clubber) (club-level club ($ 'clubber))
						($ 'book) ($ 'chapter) ($ 'section)))
		    (next (next-section club ($ 'clubber) (club-level club ($ 'clubber)) ($ 'book) ($ 'chapter) ($ 'section))))
		(clubber-section club ($ 'clubber) (club-level club ($ 'clubber))
				 ($ 'book) ($ 'chapter) ($ 'section) (if (string=? c-section "") (date->db (current-date)) ""))
		(last-section club ($ 'clubber) (list (club-level club ($ 'clubber)) ($ 'book) ($ 'chapter) ($ 'section)))
		`((text . ,($ 'section)) ;,(if (string=? c-section "") (date->db (current-date)) ($ 'section))) - no date for now
		  (next-id . ,(if (> (length next) 2) (->html-id (++ (third next) "-" (fourth next))) ""))
		  (next-title . ,(if (> (length next) 2) (++ (third next) " - " (fourth next)) "")))))
	    update-targets: #t
	    method: 'PUT
	    live: #t
	    prelude: "var ele = this;;"
	    success: "$(ele).toggleClass('done'); var book = $(ele).children().eq(0); $(ele).text(response['text']).append(book);
                      $('#easy-mark').unbind('click').bind('click', function () { $('#' + response['next-id']).click(); }).text(response['next-title']);"
	    arguments: '((clubber . "$('#clubbers').val()[0]") (book . "$('#change-book').val()")
			 (chapter . "$(this).val().split('|')[1]") (section . "$(this).val().split('|')[0]"))))
(mark-section-ajax "")

(define (combo-clubbers-ajax club)
  (ktr-ajax club "combo-clubbers" ".club-filter" 'change
  	    (lambda (club)
              (handle-exceptions
               exn
               (print "error")
               (print "hi")
  	      (let ((c-out (remove (lambda (e)
  				     (not (any (lambda (e2) (string=? (club-level club e) e2)) (string-split ($ 'clubs) ","))))
  				   (db:list "clubs" club "clubbers"))))
  		(combo-box "clubbers"
  			   (zip c-out (clubbers->names club c-out))
  			   class: "clubbers" multiple: #t))))
  	    success: "$('#clubbers-c').html(response); MyUtil.selectFilterData = new Object();"
  	    live: #t
  	    arguments: '((clubs . "(function () { var chked = ''; $('.club-filter:checked').each(function(i,v) { chked += ',' + v.id; }); return chked; })()"))))
(combo-clubbers-ajax "")

(define-awana-app-page (regexp "/[^/]*/clubbers/sections")
  (lambda (path)
    (let ((club (get-club path)))
      (add-javascript (clubber-books-ajax club))
      (add-javascript (clubber-sections-ajax club))
      (add-javascript (mark-section-ajax club))
      (add-javascript (combo-clubbers-ajax club))
      (++ (<div> class: "grid_3"
                 (<div> class: "column-header padding" "Find Clubber")
                 (<div> class: "padding column-body"
			(fold (lambda (cl o) (++ o (<input> type: "checkbox" checked: #t id: cl class: "club-filter")
						 (<label> for: cl cl))) ""
				(filter (lambda (club-name)
                                          (or (equal? club-name "Cubbies")
                                              (equal? club-name "Sparks")
                                              (equal? club-name "TnT")))
                                        (ad 'club-level)))
                        (<br>)
                        (<input> type: "text" class: "filter" id: "filter")
                        (<br>)
			(<div> id: "clubbers-c"
			       (let ((c-out
				      (name-sort club (remove (lambda (e)
								(not (any
								      (lambda (e2) (string=? (club-level club e) e2))
								      '("Cubbies" "Sparks" "TnT"))))
							      (db:list "clubs" club "clubbers")) "last")))
			       (combo-box "clubbers"
					  (zip (map (lambda (id) (html-escape id)) c-out) (clubbers->names club c-out))
					  class: "clubbers" multiple: #t)))))
          (<div> class: "grid_9" id: "info-container"
                 (<div> class: "padding column-header" id: "clubber-name" "Clubber Name")
                 (<div> class: "padding info-header" id: "info-header")
                 (<div> class: "padding column-body"
			(<div> class: "section-focus-c"
			       (<div> class: "easy-mark-c"
				      "Mark section "
				      (<button> type: "button" id: "easy-mark" class: "easy-mark-button"))
			       (<div> id: "sections-container")))))))
  css: '("/css/sections.css?ver=0")
  no-ajax: #f
  headers: (include-javascript "/js/sections.js?ver=1")
  tab: 'clubbers)

;;; stats

(define-awana-app-page (regexp "/[^/]*/stats/((attendance)|(clubbers)|(sections)|(club))")
  (lambda (path)
    (<div> class: "grid_12" (<div> class: "padding" "Smile! I'm being built right now!")))
  tab: 'stats)

;;; admin

(define-awana-app-page (regexp "/[^/]*/admin/((club)|(clubbers))")
  (lambda (path)
    (<div> class: "grid_12" (<div> class: "padding" "Smile! I'm being built right now!")))
  tab: 'admin)

(define-awana-app-page (regexp "/[^/]*/admin/leaders")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12"
                 (<div> class: "padding column-body"
                        (<span> class: "new-leader-symbol" "+") " "
                        (<a> class: "new-leader" href: (++ "/" club "/admin/leader-access") "Give Access To Leader")))
          (<div> class: "clear")
          (<div> class: "grid_12"
                 (<div> class: "padding column-header" "Leader Info"))
          (<div> class: "grid_12"
                 (<div> class: "padding column-body"
                        (<table>
                         (fold (lambda (e o)
                                 (++ o
                                     (<tr>
                                      (<td> class: "cell-name"
                                            (<a> class: "name" href: (++ "/" club "/admin/leaders/" e) (user-name e)))
                                      (<td> class: "cell-email" (user-email e))
                                      (<td> class: "cell-phone" (user-phone e)))))
                               ""
                               (club-users club))))))))
  css: '("/css/leaders.css?ver=1")
  tab: 'admin
  title: "Leaders - KtR")

(define-page (regexp "/[^/]*/admin/leader-access/authorize/.*")
  (lambda (path)
    (let* ((club (get-club path))
           (email (auth-url club path)))
      (if (neq? email 'not-found)
          (begin
            (add-javascript "$(document).ready(function() { $('#add-user-form').validationEngine('attach'); $('#name').focus(); });")
            (<div> class: "container_12"
                   (<div> class: "menu-bar menu-bar-height"
                          (<div> class: "logo"
                                 (<a> class: "main-logo" href: "http://keeptherecords.com" "Keep The Records")))
                   (<div> class: "grid_12 selected-tab-container"
                          (<div> class: "padding"
                                 (<form> action: (++ "/" club "/user/create") id: "add-user-form" method: 'POST
                                         (hidden-input 'orig-email email)
                                         (hidden-input 'auth-url path)
                                         (<h1> class: "action" (club-name club))
                                         (<h1> class: "action" "Create Your Account")
                                         (<span> class: "form-context" "Name") (<br>)
                                         (<input> class: "text validate[required,custom[onlyLetterSp],custom[ktr-name]]" type: "text" id: "name" name: "name") (<br>)
                                         (<span> class: "form-context" "Email") (<br>)
                                         (<input> class: "text validate[required,custom[email]]" type: "text" id: "email" name: "email" value: email) (<br>)
                                         (<span> class: "form-context" "Phone") (<br>)
                                         (<input> class: "text validate[required,custom[ktr-phone]]" type: "text" id: "phone" name: "phone") (<br>)
                                         (<span> class: "form-context" "Birthday") (<br>)
                                         (<input> class: "text validate[required,custom[ktr-date]]" type: "text" id: "birthday" name: "birthday") (<br>)
                                         (<span> class: "form-context" "Address") (<br>)
                                         (<input> class: "text validate[required]" type: "text" id: "address" name: "address") (<br>)
                                         (<span> class: "form-context" "Password") (<br>)
                                         (<input> class: "text validate[required]" type: "password" id: "password" name: "password") (<br>)
                                         (<span> class: "form-context" "Password Again") (<br>)
                                         (<input> class: "text validate[required,equals[password]]" type: "password" id: "password-again" name: "password-again") (<br>)
                                         (<input> type: "submit" value: "Create Your Account" class: "create"))))))
          "Not a valid authorization url.")))
  css: '("/css/club-register.css?v=2" "/css/validation-engine.jquery.css"
         "https://fonts.googleapis.com/css?family=Tangerine:regular,bold&subset=latin"
         "https://fonts.googleapis.com/css?family=Neucha&subset=latin"
         "https://fonts.googleapis.com/css?family=Josefin+Sans+Std+Light"
         "https://fonts.googleapis.com/css?family=Vollkorn&subset=latin"
         "https://fonts.googleapis.com/css?family=Permanent+Marker"
         "/css/reset.css" "/css/960.css" "/css/master.css?ver=5")
  headers: (++ (include-javascript "/js/jquery.validation-engine.js")
	       (include-javascript "/js/jquery.validation-engine-en.js"))
  no-ajax: #f
  no-session: #t
  tab: 'none)

(define-awana-app-page (regexp "/[^/]*/admin/leader-access/send-email")
  (lambda (path)
    (let* ((club (get-club path))
           (email ($ 'email))
           (link-url (++ "/" club "/admin/leader-access/authorize/"
                         (number->string (random 999999999)) (number->string (random 999999999))
                         (number->string (random 999999999)))))
      (auth-url club link-url email)
      (handle-exceptions
       exn
       "There was an error sending out the email. Please go back and try again later. If this problem persists, email me at t@keeptherecords.com."
       (send-mail subject: "Response Needed - Authorization To Access Keep The Records - Awana Record Keeping"
                  from: "t@keeptherecords.com"
                  from-name: "Keep The Records"
                  to: ($ 'email)
                  reply-to: "t@keeptherecords.com"
                  html: (++ (<p> "Hello,")
                            (<p> "You have been granted access to " (club-name club) "'s Keep The Records, Awana Record Keeping, program. To finish the authorization process, click the link below (if it doesn't work, copy and paste into a new window or tab).")
                            (<p> (<a> href: (++ "https://a.keeptherecords.com" link-url)
                                      (++ "https://a.keeptherecords.com" link-url)))
                            (<p> "Keep The Records is an Awana Record Keeping application that runs on the Internet. This email is just to notify you that the administrator for " (club-name club) " has granted the person with this email address access to " (club-name club) "'s Keep The Records account.")
                            (<p> "If you think you recieved this message in error, please reply to this email, or email me at " (<a> href: "mailto:t@keeptherecors.com" "t@keeptherecords.com")))))
      (redirect-to (++ "/" club "/admin/leader-access"))))
  method: 'POST)

(define-awana-app-page (regexp "/[^/]*/admin/leader-access")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_6"
                 (<div> class: "padding column-header" "Grant Access To Leader")
                 (<div> class: "padding column-body"
                        (<form> action: (++ path "/send-email") method: 'POST
                                (<span> class: "context" "Leader's Email Address")
                                (<br>)
                                (<input> class: "email" id: "email" name: "email")
                                (<br>)
                                (<div> class: "email-desc" "An email will be sent to the above address with a link that will allow this person to access this organization's Awana records. They will have full access to do anything, so be careful.")
                                (<input> class: "send-email" type: "submit" value: "Send Access Email"))))
          (<div> class: "grid_6"
                 (<div> class: "padding column-header" "Leaders With Access")
                 (<div> class: "padding column-body"
                        (fold (lambda (e o)
                                (++ o (<div> class: "leader-name" (user-name e))))
                              ""
                              (club-users club)))))))
  css: '("/css/leader-access.css?v=0")
  tab: 'admin
  title: "Leader Access - KtR")

(define-page (regexp "/[^/]*/user/create")
  (lambda (path)
    (let ((name ($ 'name))
          (email ($ 'email))
          (club (get-club path))
          (phone ($ 'phone))
          (birthday ($ 'birthday))
          (address ($ 'address))
          (password ($ 'password))
          (password-again ($ 'password-again))
          (attempted-path ($ 'attempted-path))
          (incoming-url ($ 'auth-url)))
      (when (not (and (auth-url club incoming-url) (string=? (auth-url club incoming-url) email)))
        (abort 'permission-denied))
      (if (string=? password password-again)
          (begin (user-name email name)
                 (user-pw email (generate-password password))
		 (user-pw-type email 'crypt)
                 (user-email email email)
                 (user-phone email phone)
                 (user-birthday email birthday)
                 (user-address email address)
                 (user-club email club)
                 (club-users club (cons email (club-users club)))
                 (send-welcome-email email club name)
                 (redirect-to "/user/login"))
          (redirect-to (++ incoming-url "?reason=passwords-dont-match")))))
  method: 'POST
  no-session: #t)

;;; sign up!

(define-awana-app-page (regexp "/[^/]*/sign-up")
  (lambda (path)
    (++ (<div> class: "grid_12"
               (<div> class: "padding"
                      (<h1> class: "sign-up" "Sign up!")
                      (<div> class: "text"
                             "I'm not quite ready for you yet, but please "
                             (<a> href: "http://eepurl.com/bGh-b" class: "subscribe" "subscribe to my newsletter")
                             " and I'll let you know once I reach the testing and launch phases.")))
        (<div> class: "grid_12"
               (<div> class: "padding" (<div> class: "bottom-line")))))
  css: '("/css/sign-up.css")
  title: "Sign up! - KtR")

;;; leader pages

(define-awana-app-page (regexp "/[^/]*/leaders/find")
  (lambda (path)
    (<div> class: "grid_12" (<div> class: "padding" "Smile. I'm being worked on right now!")))
  tab: 'leaders
  title: "Find Leaders - KtR")

;;; main app pages

(define-page "/"
  (lambda ()
    (redirect-to (++ "/" (name->id (user-club ($session 'user))) "/clubbers/dashboard"))))

(define-awana-app-page (regexp "/[^/]*/first-use")
  (lambda (path)
    "yup")
  title: "First Use - KtR")

(define-awana-app-page "/testses"
  (lambda () (++ "user: " ($session 'user))))

;;; error page

;(when (is-production?)
(page-exception-message
 (lambda (exn)
   (let ((c (with-output-to-string (lambda () (print-call-chain)))))
     (thread-start!
      (make-thread
       (lambda ()
         (send-mail subject: "KtR Error"
                    text: (with-output-to-string
                            (lambda ()
                              (display c)
                              (print-error-message exn)
                              (newline)
                              (when uri-path (write (uri-path (request-uri (current-request)))))
                              (newline)
                              (if (session-valid? (read-cookie (session-cookie-name)))
                                  (let ((user ($session 'user)))
                                    (newline)
                                    (display (++ "user: " (->string user)))
                                    (newline)
                                    (display (++ " user name: " (->string (user-name user))))
                                    (newline)
                                    (display (++ " user club: " (->string (user-club user)))))
                                  (write ""))))
                    from: "errors@keeptherecords.com"
                    from-name: "Thomas Hintz"
                    to: "errors@keeptherecords.com"
                    reply-to: "errors@keeptherecords.com")))))
   "I am sorry, but there has been an error. If this problem persists, please email us at support@keeptherecords.com"))

;;; stats

;(define-awana-app-page (regexp "/[^/]*/stats/attendance")
;  (lambda (path)
;    (<div> class: "grid_12"
;           (<div> class: "padding"
;                  (<div> class: "attendance-chart" id: "attendance-chart"))))
;  css: '("/css/attendance-stats.css")
;  headers: (++ "<!--[if IE]><script language='javascript' type='text/javascript' src='/js/flot/excanvas.min.js'></script><![endif]-->" (include-javascript "/js/flot/jquery.flot.min.js") (include-javascript "/js/attendance-stats.js"))
;  no-ajax: #f
;  tab: 'stats)

;;; personal

(define-page (regexp "/[^/]*/account-settings-trampoline")
  (lambda (path)
    (let ((club ($session 'club))
          (user ($session 'user))
          (u-name ($ 'name))
          ;(u-email ($ 'email))
          ;(u-email-again ($ 'email-again))
          (u-phone ($ 'phone))
          (u-birthday ($ 'birthday))
          (u-pw ($ 'password))
          (u-pw-again ($ 'password-again)))
      ;(if (string=? u-email u-email-again)
      ;    #f
      ;    (redirect-to (++ path "?error=emails-dont-match")))
      (if (or (string=? u-pw "") (string=? u-pw u-pw-again))
          #f
          (redirect-to (++ path "?error=passwords-dont-match")))
      (user-name user u-name)
      ;(user-email user u-email)
      (user-phone user u-phone)
      (user-birthday user u-birthday)
      (if (string=? u-pw "")
          #f
          (begin (user-pw user (generate-password u-pw))
		 (user-pw-type user 'crypt)))
      (redirect-to (++ "/" club "/clubbers/attendance?message=account-settings-update-successful"))))
  method: 'POST)

(define-awana-app-page (regexp "/[^/]*/account-settings")
  (lambda (path)
    (let ((club (get-club path))
          (user ($session 'user)))
      (++ (<div> class: "grid_12 column-header"
                 (<div> class: "padding" "My Info"))
          (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (<form> action: (++ "/" club "/account-settings-trampoline")
                                autocomplete: "off" method: 'POST
                                (<span> class: "form-context" "Name") (<br>)
                                (<input> class: "jq_watermark text name" type: "text" id: "name" name: "name"
                                         title: "John Smith" value: (user-name user)) (<br>)
                                ; email is more difficult to update because it is a key/id
                                ; therefore it is not supported fully yet
                                ;(<div> (club-name club)) (<br>) ; do we need this?
                                ;(<span> class: "form-context" "Email") (<br>)
                                ;(<input> class: "jq_watermark text" type: "text" id: "email" name: "email"
                                ;         title: "email@example.com" value: user)
                                ;(<input> class: "jq_watermark text" type: "text" id: "email-again" name: "email-again"
                                ;         title: "email@example.com" value: user) (<br>)
                                (<span> class: "form-context" "Phone") (<br>)
                                (<input> class: "jq_watermark text" type: "text" id: "phone" name: "phone"
                                         title: "123.456.7890" value: (user-phone user)) (<br>)
                                (<span> class: "form-context" "Birthday") (<br>)
                                (<input> class: "jq_watermark text" type: "text" id: "birthday" name: "birthday"
                                         title: "02/21/1997" value: (user-birthday user)) (<br>)
                                (<span> class: "form-context" "Password") (<br>)
                                (<input> class: "jq_watermark text" type: "password" id: "password" name: "password"
                                         title: "password")
                                (<input> class: "jq_watermark text" type: "password" id: "password-again"
                                         name: "password-again" title: "password again") (<br>)
                                (<input> class: "create" type: "submit" id: "submit" name: "submit" value: "Update")))))))
  css: '("/css/club-register.css?ver=2" "/css/account-settings.css")
  no-ajax: #f
  headers: (include-javascript "/js/jquery.watermark.min.js")
  title: "Account Settings - KtR")

;;; developer page

(define (define-dev-page path thunk)
  (define-page path
    (lambda ()
      (when (developer-access?) (thunk)))))

;;; loaders

(define-awana-app-page "/user/status"
  (lambda ()
    (handle-exceptions
     exn
     (send-status 500 "db down")
    (db:store "test-db-value" "test-db-key")
    (db:read "test-db-key"))
    "ok")
  no-session: #t)

(define-page "/reload-app"
  (lambda () (reload-apps (awful-apps)) "done")
  no-session: #t)

(define-page "/reload/index"
  (lambda ()
    (when (developer-access?)
      (++ (<a> href: "/reload/keep-the-records" "keep-the-records.scm")
          (<br>)
          (<br>)
          (<a> href: "/reload/setup" "setup.scm")
          (<br>)
          (<br>)
          (<a> href: "/reload/storage-funcs" "storage-funcs.scm")
          (<br>)
          (<br>)
          (<a> href: "/reload/mda" "mda.scm")
	  (<br>)
	  (<br>)
	  (<a> href: "/reload/section-data" "section.data.scm"))))
  no-session: #t
  title: "Reload Pages")

(define-page "/reload/keep-the-records"
  (lambda ()
    (when (developer-access?)
      (load "keep-the-records.scm")
      (redirect-to "/reload/index")))
  title: "Reloaded keep-the-records"
  no-session: #t)

(define-page "/reload/setup"
  (lambda ()
    (when (developer-access?)
      (load "setup.scm")
      (redirect-to "/reload/index")))
  title: "Reloaded setup"
  no-session: #t)

(define-page "/reload/section-data"
  (lambda ()
    (when (developer-access?)
      (load "section.data.scm")
      (redirect-to "/reload/index")))
  title: "Reloaded section.data.scm"
  no-session: #t)

(define-page "/reload/mda"
  (lambda ()
    (when (developer-access?)
      (load "mda.scm")
      (redirect-to "/reload/index")))
  title: "Reloaded mda.scm"
  no-session: #t)

(define-page "/reload/storage-funcs"
  (lambda ()
    (when (developer-access?)
      (load "storage-funcs.scm")
      (redirect-to "/reload/index")))
  title: "Reloaded storage-funcs.scm"
  no-session: #t)

;;; database pause/resume
(define-page "/site/admin/db/is-paused"
  (lambda () (->string (db:paused?)))
  no-session: #t)

(define-page "/site/admin/db/pause"
  (lambda () (db:pause) "paused")
  no-session: #t)

(define-page "/site/admin/db/resume"
  (lambda () (db:resume) "resumed")
  no-session: #t)

;;; includes

(include "payments.scm")
