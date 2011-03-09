;;; WARNING user/club names should be cleaned, null and / are illegal characters

(use numbers) ;; !IMPORTANT! needs to come before other eggs, may segfault otherwise (020111)
(use awful message-digest-port sha2 posix http-session spiffy-cookies html-tags html-utils srfi-13 srfi-19 regex srfi-69 doctype http-session srfi-18)

;;; Settings

(enable-ajax #t)
(ajax-library "https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")
(enable-session #t)
(enable-web-repl "/web-repl")

(define (developer-access?)
  (or (development-mode?) (string=? ($session 'user) "t@thintz.com")))

(web-repl-access-control developer-access?)

(valid-password?
 (lambda (user password)
   (if (eq? (user-email user) 'not-found)
       #f
       (password-matches? user password))))
(db:db (db:open-db "ktr-db"))

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
          (no-ajax #t)
          (tab 'none))
  (define-page (if (regexp? path) path (regexp path))
    (lambda (actual-path)
      (handle-exceptions
       exn
       (if (eq? exn 'permission-denied)
           "PERMISSION DENIED! If you think this is an error, please email me at t@thintz.com"
           (abort exn))
       (let ((club (first (string-split actual-path "/"))))
         (when (and (not (or (string=? club "user") (string=? club "club")))
                    (not (string=? ($session 'club) club)))
           (error 'permission-denied))
         (++ (if (and (session-valid? (read-cookie "awful-cookie")) ($session 'demo))
                 (<div> class: "demo"
                        (<div> class: "demo-contents"
                               "This is a DEMO"
                               " "
                               (<a> class: "demo-sign-up" href: (++ "/" club "/sign-up") "Interested in the full version?")))
                 "")
             (<div> class: "container_12"
                    (if (and (session-valid? (read-cookie "awful-cookie")) ($session 'user))
                        (<div> class: "grid_12 info-bar text-right full-width"
                           (user-name ($session 'user)) " | "
                           (<a> href: (++ "/" club "/account-settings") "My Info") " | "
                           (<a> href: "/sign-out" "Signout"))
                        "")
                    (if (not (eq? tab 'none))
                        (<div> class: "grid_12 menu-bar full-width"
                               (<div> class: "mmi-c"
                                      (<a> class: (++ "main-menu-item" (if (eq? tab 'clubbers)
                                                                           " main-menu-item-current" ""))
                                           href: (++ "/" club "/clubbers/find") "Clubbers")
                                      (<a> class: (++ "main-menu-item" (if (eq? tab 'leaders) " main-menu-item-current" ""))
                                           href: (++ "/" club "/leaders/find") "Leaders")
                                      (<a> class: (++ "main-menu-item" (if (eq? tab 'stats) " main-menu-item-current" ""))
                                           href: (++ "/" club "/stats/attendance") "Stats")
                                      (<a> class: (++ "main-menu-item" (if (eq? tab 'admin) " main-menu-item-current" ""))
                                           href: (++ "/" club "/admin/leaders") "Admin")))
                        "")
                    (<div> class: "grid_12 main-tab-bar full-width"
                           (<div> class: "logo"
                                  (<a> class: "main-logo" href: "http://keeptherecords.com" "Keep The Records"))
                           (cond
                            ((eq? tab 'clubbers)
                             (fold (lambda (e o)
                                     (++ o
                                         (<a> href: (++ "/" club "/clubbers/" (first e))
                                              class: (main-tab-class (is-current? (++ "/" club "/clubbers/" (first e))
                                                                                  actual-path))
                                              (second e))))
                                   ""
                                   '(("find" "Find") ("attendance" "Attendance") ("sections" "Sections")
                                     ("allergies" "Allergies") ("release" "Release") ("birthdays" "Birthdays")
                                     ("new" "New") ("missed" "Missed") ("dues" "Dues") ("points" "Points"))))
                            ((eq? tab 'leaders)
                             (fold (lambda (e o)
                                     (++ o
                                         (<a> href: (++ "/" club "/leaders/" (first e))
                                              class: (main-tab-class (is-current? (++ "/" club "/leaders/" (first e))
                                                                                  actual-path))
                                              (second e))))
                                   ""
                                   '(("find" "Find"))))
                            ((eq? tab 'stats)
                             (++ (<a> href: (++ "/" club "/stats/attendance")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/stats/attendance") actual-path))
                                      "Attendance")
                                        ;(<a> href: (++ "/" club "/stats/clubbers")
                                        ;     class: (main-tab-class
                                        ;             (is-current? (++ "/" club "/stats/clubbers") actual-path))
                                        ;     "Clubbers")
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
                                 ;(<a> href: (++ "/" club "/admin/club")
                                 ;     class: (main-tab-class
                                 ;             (is-current? (++ "/" club "/admin/club") actual-path))
                                 ;     "Club")
                                 (<a> href: (++ "/" club "/admin/clubbers")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/admin/clubbers") actual-path))
                                      "Clubbers")))
                            ((eq? tab 'none) "")))
                    (<div> class: "selected-tab-container" (if (regexp? path) (content actual-path) (content))))))))
    css: (append '("https://fonts.googleapis.com/css?family=Tangerine:regular,bold&subset=latin"
                   "https://fonts.googleapis.com/css?family=Neucha&subset=latin"
                   ;"https://fonts.googleapis.com/css?family=Buda:light"
                   "https://fonts.googleapis.com/css?family=Josefin+Sans+Std+Light"
                   "https://fonts.googleapis.com/css?family=Vollkorn&subset=latin"
                   "https://fonts.googleapis.com/css?family=Permanent+Marker"
                   "/css/reset.css" "/css/960.css" "/css/master.css?ver=5") css)
    title: title
    no-session: no-session
    no-ajax: no-ajax
    headers: (++ (insert-file "analytics.html") headers)
    doctype: doctype-html))

;;; development reload

(define-page "/reloadme"
  (lambda ()
    (when (developer-access?)
      (load-apps (awful-apps))
      "Reloaded"))
  no-session: #t)

;;; club/user create

(define-awana-app-page "/club/register"
  (lambda ()
    (add-javascript "$(document).ready(function() { $('#church').focus(); });")
    (<div> class: "grid_12"
           (<form> action: "/club/create" method: "post"
                   (<h1> class: "action" "Create Club")
                   (<span> class: "form-context" "Church or Association Name") (<br>)
                   (<input> class: "text" type: "text" id: "church" name: "church")
                   (<h1> class: "action" "Create Your Account")
                   (<span> class: "form-context" "Name") (<br>)
                   (<input> class: "text" type: "text" id: "name" name: "name") (<br>)
                   (<span> class: "form-context" "Email") (<br>)
                   (<input> class: "text" type: "text" id: "email" name: "email") (<br>)
                   (<span> class: "form-context" "Phone") (<br>)
                   (<input> class: "text" type: "text" id: "phone" name: "phone") (<br>)
                   (<span> class: "form-context" "Birthday") (<br>)
                   (<input> class: "text" type: "text" id: "birthday" name: "birthday") (<br>)
                   (<span> class: "form-context" "Address") (<br>)
                   (<input> class: "text" type: "text" id: "address" name: "address") (<br>)
                   (<span> class: "form-context" "Password") (<br>)
                   (<input> class: "text" type: "password" id: "password" name: "password") (<br>)
                   (<span> class: "form-context" "Password Again") (<br>)
                   (<input> class: "text" type: "password" id: "password-again" name: "password-again") (<br>)
                   (<input> type: "submit" value: "Create Club" class: "create"))))
  css: '("/css/club-register.css?v=2")
  no-ajax: #f
  no-session: #t
  tab: 'none)

;;; user login/create

(define (password-matches? user password)
  (string=? (call-with-output-digest (sha512-primitive) (cut display password <>))
            (user-pw user)))

(define (send-welcome-email email club name)
  (send-mail subject: "Welcome to Keep The Records - Awana Record Keeping"
             from: "t@keeptherecords.com"
             from-name: "Keep The Records"
             to: email
             reply-to: "t@keeptherecords.com"
             html: (++ (<p> "Welcome, " name "!")
                       (<p> "You now have access to " (club-name club) "'s Keep The Records, Awana Record Keeping program. To login and start using the program you can go to " (<a> href: "https://a.keeptherecords.com" "https://a.keeptherecords.com") ". You can also find the login link at the KtR blog - " (<a> href: "http://keeptherecords.com" "http://keeptherecords.com") ".")
                       (<p> "If you ever have any questions or just want to give me feedback, just email Thomas Hintz at " (<a> href: "mailto:t@keeptherecords.com" "t@keeptherecords.com") " or give me a call at 906.934.6413. Also, please feel free to follow the KtR blog at " (<a> href: "http://keeptherecords.com/blog" "http://keeptherecords.com/blog") ".")
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
           (<form> action: "/login-trampoline" method: "POST"
                   (<h1> class: "action" "Login to Keep the Records")
                   (<span> class: "form-context" "Email") (<br>)
                   (<input> class: "text" type: "text" id: "user" name: "user") (<br>)
                   (<span> class: "form-context" "Password") (<br>)
                   (<input> class: "text" type: "password" id: "password" name: "password") (<br>)
                   (<input> class: "create" type: "submit" value: "Enjoy KtR!"))))
  no-ajax: #f
  css: '("/css/club-register.css?ver=2")
  no-session: #t)

(define-page (regexp "/sign-out")
  (lambda (path)
    (session-destroy! (read-cookie "awful-cookie"))
    (delete-cookie! "awful-cookie")
    "You have been logged out"))

(define-awana-app-page (regexp "/[^/]*/join-club")
  (lambda (path)
    (++ (<h1> "Join A Club")
        "To begin, you must be authorized to work with an Awana club."
        (<br>) (<br>)
        "You can either:"
        (<ul> (<li> (<a> href: "/club/authorize-me" "Ask for authorization from an existing club"))
              (<li> (<a> href: "/club/register" "Create a new club"))))))

(define (as-db-unique proc unique-val start-val)
  (when (> start-val 2000) (abort 'no-unique-val-found))
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
      (db:add-permission (->string sid)
                         (lambda (path-list) #t))
      (let ((u-name (as-db-unique (lambda (u-n) (user-email u-n)) "demo" 1)))
        (setup-demo u-name)
        (html-page
         ""
         headers: (<meta> http-equiv: "refresh"
                          content: (++ "0;url=/" (user-club u-name) "/clubbers/attendance"))))))
  no-session: #t)

;;; club pages

(define-awana-app-page "/club/create"
  (lambda ()
    (let* ((church ($ 'church))
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
                 (user-pw u-email (call-with-output-digest (sha512-primitive) (cut display (->string u-pw) <>)))
                 (club-users club (cons email (club-users club)))
                 (send-welcome-email u-email club u-name)
                 (html-page
                  ""
                  headers: (<meta> http-equiv: "refresh"
                                   content: (++ "0;url=" "/user/login"))))
          (if (eq? (user-name u-email) 'not-found)
              "Passwords don't match, please go back and re-enter your info."
              "Email already in use."))))
  no-session: #t)

;;; clubber pages

(define (get-club path)
  (first (string-split path "/")))

(define-awana-app-page (regexp "/[^/]*/clubbers/register")
  (lambda (path)
    (let ((club (get-club path)))
      (ajax "lookup-parent" 'parent-name-1 'change
            (lambda ()
              (if ($ 'p-name)
                  (map (lambda (data)
                         (cond ((string=? data "name") `(parent-name-1 . ,(parent-name club ($ 'p-name))))
                               ((string=? data "spouse") `(parent-name-2 . ,(parent-spouse club ($ 'p-name))))
                               (#t `(,(string->symbol data) .
                                     ,(db:read "clubs" club "parents" ($ 'p-name) data)))))
                       (db:list "clubs" club "parents" ($ 'p-name)))
                  '()))
            success: "$.each(response, function(id, html) { $('#' + id).val(html).addClass('filled'); })"
            update-targets: #t
            method: 'GET
            arguments: '((p-name . "parentIds[parentNames.indexOf($('#parent-name-1').val())]")))
      (++ (<div> class: "clear")
          (<div> class: "grid_12" (<div> class: "success" id: "success" (if ($ 'success) "Clubber Added Successfully" "")))
          (<div> class: "grid_6" (<div> class: "padding column-header" "Register New Clubber"))
          (<div> class: "clear clear-no-space")
          (<div> class: "grid_6"
                 (<div> class: "padding column-body"
                        (<form> action: (++ "/" club  "/clubbers/create" (if ($ 'from) (++ "?from=" ($ 'from)) ""))
                                method: "post"
                                (<table> (<tr> (<td> class: "label" (<span> class: "label-name" id: "label-name" "Name"))
                                               (<td> (<input> id: "name" class: "name" name: "name")))
                                         (<tr> (<td> class: "label" (<span> class: "label grade" "Grade"))
                                               (<td> (combo-box "grade" '(("age-2-or-3" "Age 2 or 3")
                                                                          ("pre-k" "Pre-k") "K" "1"
                                                                          "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12")
                                                                name: "grade" class: "grade" first-empty: #t)))
                                         (<tr> (<td> class: "label" (<span> class: "label birthday" "Birthday"))
                                               (<td> (<input> class: "birthday" id: "birthday" name: "birthday")))
                                         (<tr> (<td> class: "label" (<span> class: "label club" id: "label-club" "Club"))
                                               (<td> (combo-box "club-level"
                                                                '("Puggles" "Cubbies" "Sparks" "TnT" "Trek" "Journey")
                                                                name: "club-level" class: "club" first-empty: #t)))
                                         (<tr> (<td> class: "label" (<span> class: "label allergies" "Allergies"))
                                               (<td> (<input> class: "allergies" id: "allergies" name: "allergies")))
                                         (<tr> (<td>) (<td> (<span> class: "parent-label" "Parent/Guardian")))
                                         (<tr> (<td> class: "label" (<span> class: "label parent-name" "Parent Name 1"))
                                               (<td> (<input> class: "parent-name" id: "parent-name-1"
                                                              name: "parent-name-1")))
                                         (<tr> (<td> class: "label" (<span> class: "label parent-name" "Parent Name 2"))
                                               (<td> (<input> class: "parent-name" id: "parent-name-2"
                                                              name: "parent-name-2")))
                                         (<tr> (<td> class: "label" (<span> class: "label email" "Email"))
                                               (<td> (<input> class: "email" id: "email" name: "email")))
                                         (<tr> (<td> class: "label" (<span> class: "label phone" "Phone 1"))
                                               (<td> (<input> class: "phone" id: "phone-1" name: "phone-1")))
                                         (<tr> (<td> class: "label" (<span> class: "label phone" "Phone 2"))
                                               (<td> (<input> class: "phone" id: "phone-2" name: "phone-2")))
                                         (<tr> (<td> class: "label" (<span> class: "label address" "Address"))
                                               (<td> (<input> class: "address" id: "address" name: "address")))
                                         (<tr> (<td> class: "label" (<span> class: "label release-to" "Release To"))
                                               (<td> (<input> class: "release-to" id: "release-to" name: "release-to")))
                                         (<tr> (<td> colspan: "2"
                                                     (<div> class: "create-clubber-container"
                                                            (<input> type: "submit" class: "create-clubber"
                                                                     value: "Create Clubber"))))))))
          (hidden-input 'parent-names (fold (lambda (e o) (++ o "|" (parent-name club e)))
                                            "" (db:list "clubs" club "parents")))
          (hidden-input 'parent-ids (fold (lambda (e o) (++ o "|" e))
                                          "" (db:list "clubs" club "parents")))
          (<div> class: "grid_4"
                 (<div> class: "info-header name-info-header" (<div> class: "padding" "Adding a Clubber"))
                 (<div> class: "info-body name-info-body" (<div> class: "padding" "This is a person in your club. Once this clubber is added, you can take attendance, view contact info, and lots more."))
                 (<div> class: "info-header parent-info-header" (<div> class: "padding" "Parent Info"))
                 (<div> class: "info-body parent-info-body" (<div> class: "padding" "To retrieve information about a previously entered parent/guardian, just start typing thier name and select the parent/guardian name that appears, and their info will be pre-filled."))))))
  css: '("/css/add-clubber.css" "/css/autocomplete.css" "/css/clubbers-index.css")
  headers: (++ (include-javascript "/js/add-clubber.js") (include-javascript "/js/autocomplete.js"))
  no-ajax: #f
  tab: 'clubbers
  title: "Register Clubber - Club Night - KtR")

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
;;; also add security within awana-app-page or something
    (let ((club (get-club path))
           (m-name ($ 'name))
           (from ($ 'from)))
      (name club m-name m-name)
      (grade club m-name ($ 'grade))
      (birthday club m-name ($ 'birthday))
      (club-level club m-name ($ 'club-level))
      (allergies club m-name ($ 'allergies))
      (primary-parent club m-name ($ 'parent-name-1))
      (date-registered club m-name (date->db (current-date)))
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
      (html-page
       ""
       headers: (<meta> http-equiv: "refresh"
                        content: (++ "0;url=" (if (not (eq? from #f))
                                                  from
                                                  (++ "/" club "/clubbers/register?success=true")))))))
  no-session: #t)

(define (present-clubbers club date)
  (filter (lambda (m-name)
            (if (present club m-name date) #t #f)) (db:list "clubs" club "clubbers")))

(define (attendees-html club date)
  (let ((present-clubbers (sort (present-clubbers club date) string<)))
    (++ "In Attendance: "
        (number->string (fold (lambda (m c) (+ c 1)) 0 present-clubbers))
        (<br>) (<br>)
        (fold (lambda (m-name o)
                (++ o (<a> href: (++ "/" club "/clubbers/info/" m-name) (name club m-name)) (<br>)))
              ""
              present-clubbers))))

(define (todays-mm) (date->string (current-date) "~m"))
(define (todays-dd) (date->string (current-date) "~d"))
(define (todays-yy) (date->string (current-date) "~y"))
(define (todays-yyyy) (date->string (current-date) "~Y"))

;;; take attendance

(define-awana-app-page (regexp "/[^/]*/clubbers/attendance")
  (lambda (path)
    (let ((club (get-club path))
          (date (++ (or ($ 'year) (todays-yyyy)) "/" (or ($ 'month) (todays-mm)) "/" (or ($ 'day) (todays-dd)))))
      (ajax "clubber-attendance-info" 'clubbers '(change keypress)
            (lambda ()
              (let ((n ($ 'name)))
                (if n
                    `((clubber-name . ,(name club n))
                      (present . ,(present club n date))
                      (bible . ,(bible club n date))
                      (handbook . ,(handbook club n date))
                      (uniform . ,(uniform club n date))
                      (friend . ,(friend club n date))
                      (extra . ,(extra club n date))
                      (points-total . ,(total-points club n))
                      (allergies . ,(allergies club n))
                      (club-level . ,(club-level club n))
                      (notes . ,(notes club n))
                      (attendees-html . ,(attendees-html club date)))
                    '())))
            success: "loadClubberInfo(response);"
            update-targets: #t
            method: 'GET
            arguments: '((name . "$('#clubbers').val()[0]")))
      (ajax "save-present" 'present 'click
            (lambda ()
              (present club ($ 'name) date (if (string=? ($ 'present) "false") #f #t)))
            method: 'PUT
            arguments: '((name . "$('#clubbers').val()[0]") (present . "stringToBoolean($('#present').val())")))
      (ajax "save-bible" 'bible 'click
            (lambda ()
              (bible club ($ 'name) date (if (string=? ($ 'bible) "false") #f #t)))
            method: 'PUT
            arguments: '((name . "$('#clubbers').val()[0]") (bible . "stringToBoolean($('#bible').val())")))
      (ajax "save-handbook" 'handbook 'click
            (lambda ()
              (handbook club ($ 'name) date (if (string=? ($ 'handbook) "false") #f #t)))
            method: 'PUT
            arguments: '((name . "$('#clubbers').val()[0]") (handbook . "stringToBoolean($('#handbook').val())")))
      (ajax "save-uniform" 'uniform 'click
            (lambda ()
              (uniform club ($ 'name) date (if (string=? ($ 'uniform) "false") #f #t)))
            method: 'PUT
            arguments: '((name . "$('#clubbers').val()[0]") (uniform . "stringToBoolean($('#uniform').val())")))
      (ajax "save-friend" 'friend 'click
            (lambda ()
              (friend club ($ 'name) date (if (string=? ($ 'friend) "false") #f #t)))
            method: 'PUT
            arguments: '((name . "$('#clubbers').val()[0]") (friend . "stringToBoolean($('#friend').val())")))
      (ajax "save-extra" 'extra 'click
            (lambda ()
              (extra club ($ 'name) date (if (string=? ($ 'extra) "false") #f #t)))
            method: 'PUT
            arguments: '((name . "$('#clubbers').val()[0]") (extra . "stringToBoolean($('#extra').val())")))
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
          (<div> class: "grid_3 column-header" (<div> class: "padding" "View Attendees"))
          (<div> class: "grid_3 column-body"
                 (<div> class: "padding"
                        (<input> type: "text" class: "filter" id: "filter")
                        (combo-box "clubbers"
                                   (map (lambda (e)
                                          `(,e . ,(name club e)))
                                        (name-sort club (db:list "clubs" club "clubbers") "last"))
                                   class: "clubbers" multiple: #t)))
          (<div> class: "grid_6 column-body"
                 (<div> class: "padding"
                        (<div> class: "description-container" id: "description-container"
                                      "To begin, click on a name to the left" (<br>) (<br>)
                                      "<--" (<br>) (<br>)
                                      "You can also filter (sort of like search) the names by typing into the box above the clubbers")
                        (<div> class: "clubber-data" id: "clubber-data"
                               (<div> class: "attendance-container"
                                      (<div> class: "attendance-button" id: "present" "Present"
                                             (<input> class: "present" type: "button" id: "present" value: ""))
                                      (<div> class: "attendance-button" id: "bible" "Bible"
                                             (<input> class: "bible" type: "button" id: "bible" value: ""))
                                      (<div> class: "attendance-button" id: "handbook" "Handbook"
                                             (<input> class: "handbook" type: "button" id: "handbook" value: ""))
                                      (<div> class: "attendance-button" id: "uniform" "Uniform"
                                             (<input> class: "uniform" type: "button" id: "uniform" value: ""))
                                      (<div> class: "attendance-button" id: "friend" "Friend"
                                             (<input> class: "friend" type: "button" id: "friend" value: ""))
                                      (<div> class: "attendance-button" id: "extra" "Extra"
                                             (<input> class: "extra" type: "button" id: "extra" value: "+1")))
                               (<div> class: "points-container"
                                      (<div> class: "points" id: "points-total")
                                      (<div> class: "points points-label" " points"))
                               (<div> class: "allergy-info" id: "allergy-container"
                                      (<div> class: "allergic-to info" "Allergic To:") (<br>)
                                      (<div> class: "allergic-to-item" id: "allergies" ""))
                               (<div> class: "notes info" id: "notes" ""))))
          (<div> class: "grid_3 column-body"
              (<div> class: "tab-body padding"
                     (<div> class: "attendees" id: "attendees"
                            (attendees-html club date)))))))
  headers: (include-javascript "/js/attendance.js")
  no-ajax: #f
  css: '("/css/attendance.css?ver=3")
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
                       (let ((n1 (string-split (name club e1) " "))
                             (n2 (string-split (name club e2) " ")))
                         (string< (++ (second n1) " " (first n1))
                                  (++ (second n2) " " (first n2))))
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
                         (<a> href: (++ "/" club "/clubbers/register") class: "new-clubber" "Add New Clubber")))))
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
                (if (> (length clubbers) 0) (<div> class: "grid_2 column-body"
                                                   (<div> class: "padding"
                                                          (clubbers->urls club clubbers sort-by-first))) ""))))))
  css: '("/css/clubbers-index.css")
  tab: 'clubbers
  title: "Clubbers - Club Night - KtR")

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
                                                   (sort (list-days club clubber year month) string<)))
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

(define-awana-app-page (regexp "/[^/]*/clubbers/info/[^/]*")
  (lambda (path)
    (let* ((clubber (get-clubber path))
           (club (get-club path))
           (p-parent (primary-parent club clubber))
           (dates (attendance-dates club clubber)))
      (++ (<div> class: "grid_12" (<div> class: "column-header padding" (name club clubber)))
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
                                                           ("Friend" ,(lambda (c cl d) (friend c cl d))))))))))))))
  css: '("/css/clubbers.css")
  tab: 'clubbers
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
                                 (ajax (++ "update-thank-you" c)
                                       (string->symbol (++ "thank-you" c))
                                       'click
                                       (lambda ()
                                         (thank-you club c (date->db (current-date)))
                                         (date->db (current-date)))
                                       target: (++ "thank-you" c)
                                       method: 'PUT)
                                 (++ o
                                     (<tr> (<td> (<a> href: (++ "/" club "/clubbers/info/" c)
                                                      class: "clubber-name"
                                                      (name club c)))
                                           (<td> (date-registered club c))
                                           (<td> (let ((t (thank-you club c)))
                                                   (if t
                                                       (<div> class: "yes" t)
                                                       (<div> class: "no" id: (++ "thank-you" c) "No"))))
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
                                   (ajax (++ "update-miss-you" e)
                                         (string->symbol (++ "miss-you" e))
                                         'click
                                         (lambda ()
                                           (miss-you club e (date->db (current-date)))
                                           (date->db (current-date)))
                                         target: (++ "miss-you" e)
                                         method: 'PUT)
                                   (++ o
                                       (if (missed-clubs? club e c-meetings)
                                           (<tr> (<td> (<a> href: (++ "/" club "/clubbers/info/" e)
                                                            class: "clubber-url" (name club e)))
                                                 (<td> (let ((t (miss-you club e)))
                                                         (if t
                                                             (<div> class: "yes" t)
                                                             (<div> class: "no" id: (++ "miss-you" e) "No")))))
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
                                 (ajax (++ "dues-receipt" e)
                                       (string->symbol (++ "dues-receipt" e))
                                       'change
                                       (lambda ()
                                         (dues-receipt club e ($ 'dues-receipt)))
                                       arguments: `((dues-receipt . ,(++ "$('#dues-receipt" e "').val()")))
                                       method: 'PUT)
                                 (++ o
                                     (<tr> (<td> (<a> href: (++ "/" club "/clubbers/info/" e)
                                                      class: "clubber-url" (name club e)))
                                           (<td> (let ((t (dues-receipt club e)))
                                                   (if t
                                                       (<input> class: "yes" id: (++ "dues-receipt" e) value: t)
                                                       (<input> class: "no" id: (++ "dues-receipt" e))))))
                                     ""))
                               ""
                               (name-sort club (db:list "clubs" club "clubbers") "last"))))))))
  no-ajax: #f
  tab: 'clubbers
  css: '("/css/clubbers-index.css?ver=2" "/css/clubbers-dues.css?ver=0")
  title: "Dues - Club Night - KtR")

(define (date->date-year d yyyy)
  (make-date 0 0 0 0 (date-day d) (date-month d) yyyy))

(define (in-week? d1 d2)
  ; is d2 within the same week as d1
  (let ((week-start (date-subtract-duration d1 (make-duration days: (date-week-day d1))))
        (week-end (date-add-duration d1 (make-duration days: (- 6 (date-week-day d1))))))
    (and (date>=? d2 week-start) (date<=? d2 week-end))))

(define (birthdays-this-week club clubbers)
  ;; use a manual make-date instead of current-date to keep the days time at 0
  (let ((t (make-date 0 0 0 0 (string->number (todays-dd)) (string->number (todays-mm)) (string->number (todays-yyyy)))))
    (filter (lambda (c)
              (let ((c-b (db->date (birthday club c))))
                (and c-b
                     (in-week? t (date->date-year c-b (string->number (todays-yyyy)))))))
            clubbers)))

(define-awana-app-page (regexp "/[^/]*/clubbers/birthdays")
  (lambda (path)
    (let* ((club (get-club path))
           (d1 (make-date 0 0 0 0 (string->number (todays-dd)) (string->number (todays-mm)) (string->number (todays-yyyy))))
           (week-start (date->string (date-subtract-duration d1 (make-duration days: (date-week-day d1))) "~m/~d"))
           (week-end (date->string (date-add-duration d1 (make-duration days: (- 6 (date-week-day d1)))) "~m/~d")))
      (++ (<div> class: "grid_12"
                 (<div> class: "padding column-header" (++ "Birthdays from " week-start " to " week-end)))
          (<div> class: "grid_12"
                 (<div> class: "padding column-body"
                        (<table>
                         (fold (lambda (e o)
                                 (++ o
                                     (<tr> class: "clubber-row"
                                           (<td> class: "name-cell"
                                                 (<a> class: "clubber-name"
                                                      href: (++ "/" club "/clubbers/info/" e) (name club e)))
                                           (<td> class: "aux-cell"
                                                 (birthday club e)))))
                               ""
                               (birthdays-this-week club (db:list "clubs" club "clubbers")))))))))
  tab: 'clubbers
  title: "Birthdays - Club Night - KtR"
  css: '("/css/key-value.css?ver=1" "/css/clubbers-index.css?ver=2"))

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

(define (tnt-book-names) '("Start Zone"
                           "The Ultimate Adventure Series Book One"
                           "The Ultimate Adventure Series Book Two"
                           "The Ultimate Challenge Series Book One"
                           "The Ultimate Challenge Series Book Two"))

(define (range from/to . to)
  (let ((f (if (= (length to) 0) -1 (- from/to 1)))
        (t (if (> (length to) 0) (first to) from/to)))
    (do ((i (- t 1) (- i 1))
         (l '() (cons i l)))
        ((= i f) l))))

(define (book-chapters club-level book)
  (cond ((string-ci=? club-level "tnt")
         (if (= (string->number (->string book)) 0) 1 8))
        (#t #f)))

(define (sections-list club clubber book)
  (map (lambda (chapter)
         (map (lambda (section)
                (clubber-section club clubber (->string book) (number->string chapter) (number->string section)))
              (range 12)))
       (range 1 (+ (book-chapters (club-level club clubber) book) 1))))

(define (sec-cl border finished)
  (++ border " " (if finished "finished" "unfinished")))

(define (sections-table sections)
  (<table> id: "regular-sections"
           (<tr> (<td> class: "border")
                 (<td> class: "border" "Section 0")
                 (<td> class: "border" "1") (<td> class: "border" "2") (<td> class: "border" "3")
                 (<td> class: "border" "4") (<td> class: "border" "5") (<td> class: "border" "6")
                 (<td> class: "border-end" "7")
                 (<td> class: "cell-sep")
                 (<td> class: "border" "Silver")
                 (<td> class: "border" "Gold") (<td> class: "border-end" "Gold"))
           (let ((c 0))
             (fold (lambda (e o)
                     (set! c (+ c 1))
                     (let ((n (number->string c)))
                       (++ o
                           (<tr> (<td> class: "border" c)
                                 (<td> class: (sec-cl "border" (first e)) id: (++ n ".0"))
                                 (<td> class: (sec-cl "border" (second e)) id: (++ n ".1"))
                                 (<td> class: (sec-cl "border" (third e)) id: (++ n ".2"))
                                 (<td> class: (sec-cl "border" (fourth e)) id: (++ n ".3"))
                                 (<td> class: (sec-cl "border" (fifth e)) id: (++ n ".4"))
                                 (<td> class: (sec-cl "border" (sixth e)) id: (++ n ".5"))
                                 (<td> class: (sec-cl "border" (seventh e)) id: (++ n ".6"))
                                 (<td> class: (sec-cl "border-end" (eighth e)) id: (++ n ".7"))
                                 (<td> class: "cell-sep")
                                 (<td> class: (sec-cl "border" (ninth e)) id: (++ n ".8"))
                                 (<td> class: (sec-cl "border" (tenth e)) id: (++ n ".9"))
                                 (<td> class: (sec-cl "border-end" (list-ref e 10)) id: (++ n ".10"))))))
                   ""
                   (take sections 7)))
           (let ((end (first (drop sections 7))))
             (<tr> (<td> class: "border-bottom" "8")
                   (<td> class: (sec-cl "border-bottom" (first end)) id: "8.0")
                   (<td> class: (sec-cl "border-bottom" (second end)) id: "8.1")
                   (<td> class: (sec-cl "border-bottom" (third end)) id: "8.2")
                   (<td> class: (sec-cl "border-bottom" (fourth end)) id: "8.3")
                   (<td> class: (sec-cl "border-bottom" (fifth end)) id: "8.4")
                   (<td> class: (sec-cl "border-bottom" (sixth end)) id: "8.5")
                   (<td> class: (sec-cl "border-bottom" (seventh end)) id: "8.6")
                   (<td> class: (sec-cl "border-bottom-end" (eighth end)) id: "8.7")
                   (<td> class: "cell-sep")
                   (<td> class: (sec-cl "border-bottom" (ninth end)) id: "8.8")
                   (<td> class: (sec-cl "border-bottom" (tenth end)) id: "8.9")
                   (<td> class: (sec-cl "border-bottom-end" (list-ref end 10)) id: "8.10")))))

(define (start-zone-table sections)
  (<table> (<tr> (fold (lambda (s o)
                         (++ o (<td> class: (++ "border border-bottom "
                                                (if s "finished" "unfinished")) "")))
                       ""
                       (take (first sections) 7))
                 (<td> class: (++ "border border-bottom-end "
                                  (if (eighth (first sections)) "finished" "unfinished")) ""))))

(define (next-section current-section section-list)
  (let ((c (first current-section)) (s (second current-section))
        (csl (list-ref section-list (- (first current-section) 1))))
    (let ((n (cond ((= s (length csl))
                    `(,(+ c 1) 0))     ; done with chapter
                   (#t
                    `(,c ,(+ s 1)))))) ; done with section
      (if (list-ref (list-ref section-list (- (first n) 1)) (second n))
          (next-section n section-list)
          n))))

(define-awana-app-page (regexp "/[^/]*/clubbers/sections")
  (lambda (path)
    (let ((club (get-club path)))
      (ajax "clubber-sections" 'clubbers '(change keypress)
            (lambda ()
              (let* ((clubber ($ 'clubber))
                     (c-book (book club clubber)))
                `((book-num . ,c-book)
                  (books . ,(tnt-book-names))
                  (name . ,clubber)
                  (last-section . ,(last-section club clubber))
                  (sections . ,(let ((s (sections-list club clubber c-book)))
                                 (if (< (length s) 2)
                                     (start-zone-table s)
                                     (sections-table s)))))))
            success: "loadClubberSections(response);"
            update-targets: #t
            method: 'GET
            arguments: '((clubber . "$('#clubbers').val()[0]")))
      (ajax "clubber-book" 'change-book 'change
            (lambda ()
              (let* ((clubber ($ 'clubber))
                     (c-book (string->number ($ 'book))))
              (book club clubber c-book)
              `((book-num . ,c-book)
                  (books . ,(tnt-book-names))
                  (name . ,clubber)
                  (last-section . ,(last-section club clubber))
                  (sections . ,(let ((s (sections-list club clubber c-book)))
                                 (if (< (length s) 2)
                                     (start-zone-table s)
                                     (sections-table s)))))))
            success: "loadClubberSections(response);"
            update-targets: #t
            method: 'PUT
            arguments: '((clubber . "$('#clubbers').val()[0]") (book . "$('#change-book').attr('selectedIndex')")))
      (ajax "mark-section" 'mark-section 'click
            (lambda ()
              (let ((c-book ($ 'book)) (clubber ($ 'clubber)) (chapter ($ 'chapter)) (section ($ 'section)))
                (clubber-section club clubber c-book (->string chapter) (->string section) #t)
                (last-section club clubber (next-section `(,(string->number chapter) ,(string->number section))
                                                         (sections-list club clubber c-book)))
                `((book-num . ,c-book)
                  (books . ,(tnt-book-names))
                  (name . ,clubber)
                  (last-section . ,(last-section club clubber))
                  (sections . ,(let ((s (sections-list club clubber c-book)))
                                 (if (< (length s) 2)
                                     (start-zone-table s)
                                     (sections-table s)))))))
            success: "loadClubberSections(response);"
            update-targets: #t
            method: 'PUT
            arguments: '((clubber . "$('#clubbers').val()[0]") (book . "$('#change-book').attr('selectedIndex')")
                        (chapter . "lastChapter") (section . "lastSection")))
      (++ (<div> class: "grid_3"
                 (<div> class: "column-header padding" "Find Clubber")
                 (<div> class: "padding column-body"
                        (<input> type: "checkbox" id: "puggles" disabled: #t) (<label> for: "puggles" "Puggles")
                        (<input> type: "checkbox" id: "cubbies" disabled: #t) (<label> for: "cubbies" "Cubbies")
                        (<input> type: "checkbox" id: "sparks" disabled: #t) (<label> for: "sparks" "Sparks")
                        (<input> type: "checkbox" id: "tnt" checked: #t) (<label> for: "tnt" "TnT")
                        (<input> type: "checkbox" id: "trek" disabled: #t) (<label> for: "trek" "Trek")
                        (<input> type: "checkbox" id: "journey" disabled: #t) (<label> for: "journey" "Journey")
                        (<br>)
                        (<input> type: "text" class: "filter" id: "filter")
                        (<br>)
                        (combo-box "clubbers"
                                   (clubbers->names club (club-filter club (db:list "clubs" club "clubbers") "tnt"))
                                   class: "clubbers" multiple: #t)))
          (<div> class: "grid_9" id: "default-info"
                 (<div> class: "padding column-header" "Mark Sections")
                 (<div> class: "padding column-body"
                        "To begin, select a name <--"))
          (<div> class: "grid_9 hidden" id: "info-container"
                 (<div> class: "padding column-header" id: "clubber-name" "Clubber Name")
                 (<div> class: "padding info-header"
                        (combo-box "change-book" '() class: "change-book"))
                 (<div> class: "padding column-body"
                        (<div> class: "easy-mark"
                               "Mark section "
                               (<input> type: "button" id: "mark-section" class: "easy-mark-button"))
                        (<div> id: "sections-container"))))))
  css: '("/css/sections.css")
  no-ajax: #f
  headers: (include-javascript "/js/sections.js")
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
      (if (not (eq? email 'not-found))
          (begin
            (add-javascript "$(document).ready(function() { $('#name').focus(); });")
            (<div> class: "container_12"
                   (<div> class: "menu-bar menu-bar-height"
                          (<div> class: "logo"
                                 (<a> class: "main-logo" href: "http://keeptherecords.com" "Keep The Records")))
                   (<div> class: "grid_12 selected-tab-container"
                          (<div> class: "padding"
                                 (<form> action: (++ "/" club "/user/create") method: "post"
                                         (hidden-input 'orig-email email)
                                         (hidden-input 'auth-url path)
                                         (<h1> class: "action" (club-name club))
                                         (<h1> class: "action" "Create Your Account")
                                         (<span> class: "form-context" "Name") (<br>)
                                         (<input> class: "text" type: "text" id: "name" name: "name") (<br>)
                                         (<span> class: "form-context" "Email") (<br>)
                                         (<input> class: "text" type: "text" id: "email" name: "email" value: email) (<br>)
                                         (<span> class: "form-context" "Phone") (<br>)
                                         (<input> class: "text" type: "text" id: "phone" name: "phone") (<br>)
                                         (<span> class: "form-context" "Birthday") (<br>)
                                         (<input> class: "text" type: "text" id: "birthday" name: "birthday") (<br>)
                                         (<span> class: "form-context" "Address") (<br>)
                                         (<input> class: "text" type: "text" id: "address" name: "address") (<br>)
                                         (<span> class: "form-context" "Password") (<br>)
                                         (<input> class: "text" type: "password" id: "password" name: "password") (<br>)
                                         (<span> class: "form-context" "Password Again") (<br>)
                                         (<input> class: "text" type: "password" id: "password-again" name: "password-again") (<br>)
                                         (<input> type: "submit" value: "Create Your Account" class: "create"))))))
          "Not a valid authorization url.")))
  css: '("/css/club-register.css?v=2"
         "https://fonts.googleapis.com/css?family=Tangerine:regular,bold&subset=latin"
         "https://fonts.googleapis.com/css?family=Neucha&subset=latin"
         "https://fonts.googleapis.com/css?family=Josefin+Sans+Std+Light"
         "https://fonts.googleapis.com/css?family=Vollkorn&subset=latin"
         "https://fonts.googleapis.com/css?family=Permanent+Marker"
         "/css/reset.css" "/css/960.css" "/css/master.css?ver=5")
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
       "There was an error sending out the email. Please go back and try again later. If this problem persists, email me at t@keeptherecords.com or call me at 906.934.6413."
       (send-mail subject: "Authorization To Access Keep The Records - Awana Record Keeping"
                  from: "t@keeptherecords.com"
                  from-name: "Keep The Records"
                  to: ($ 'email)
                  reply-to: "t@keeptherecords.com"
                  html: (++ (<p> "Hello,")
                            (<p> "You have be
    '()en granted access to " (club-name club) "'s Keep The Records, Awana Record Keeping, program. To finish the authorization process, click the link below (if it doesn't work, copy and paste into a new window or tab).")
                            (<p> (<a> href: (++ "https://a.keeptherecords.com" link-url)
                                      (++ "https://a.keeptherecords.com" link-url)))
                            (<p> "Keep The Records is an Awana Record Keeping application that runs on the Internet. This email is just to notify you that the administrator for " (club-name club) " has granted the person with this email address access to " (club-name club) "'s Keep The Records account.")
                            (<p> "If you think you recieved this message in error, please reply to this email, or email me at " (<a> href: "mailto:t@keeptherecors.com" "t@keeptherecords.com")))))
      (redirect-to (++ "/" club "/admin/leader-access")))))

(define-awana-app-page (regexp "/[^/]*/admin/leader-access")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_6"
                 (<div> class: "padding column-header" "Grant Access To Leader")
                 (<div> class: "padding column-body"
                        (<form> action: (++ path "/send-email") method: "GET"
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
                 (user-pw email (call-with-output-digest (sha512-primitive) (cut display (->string password) <>)))
                 (user-email email email)
                 (user-phone email phone)
                 (user-birthday email birthday)
                 (user-address email address)
                 (user-club email club)
                 (club-users club (cons email (club-users club)))
                 (send-welcome-email email club name)
                 (redirect-to "/user/login"))
          (redirect-to (++ incoming-url "?reason=passwords-dont-match")))))
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
    (redirect-to (++ "/" (name->id (user-club ($session 'user))) "/clubbers/find"))))

(define-awana-app-page (regexp "/[^/]*/first-use")
  (lambda (path)
    "yup")
  title: "First Use - KtR")

(define-awana-app-page "/testses"
  (lambda () (++ "user: " ($session 'user))))

;;; error page

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
                              (write (uri-path (request-uri (current-request))))
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
                    from: "t@keeptherecords.com"
                    from-name: "Thomas Hintz"
                    to: "t@thintz.com"
                    reply-to: "t@thintz.com")))))
   (++ "<link  href='//fonts.googleapis.com/css?family=Rock+Salt:regular' rel='stylesheet' type='text/css' >"
       "<link  href='//fonts.googleapis.com/css?family=IM+Fell+Great+Primer:regular' rel='stylesheet' type='text/css' >"
       (<div> class: "error-outer-div" style: "background-color: white;"
              (<div> class: "oh-no-div" style: "background-color: black; width: 100%; height: 200px;"
                     (<h1> class: "oh-no" style: "font-family: Rock Salt; padding-top: 50px; margin-left: 10px; font-size: 100px; font-style: italic; font-weight: 700; margin-bottom: 0px; color: #ff8100; text-shadow: blue -2px -2px, grey 3px 3px;" "Oh no!"))
              (<div> style: "font-family: IM Fell Great Primer; font-size: 34px; margin-left: 10px; padding-top: 10px; padding-bottom: 5px;" "I messed something up!")
              (<div> style: "font-style: italic; color: grey; margin-left: 35px;" "An email has just been sent to my personal inbox detailing what went wrong and I will fix this as quickly as possible.")
              (<br>)
              (<div> style: "font-family: Rock Salt; padding-left: 10px; padding-top: 15px; padding-bottom: 15px; font-size: 30px; font-style: italic; font-weight: 700; color: #ff8100; background-color: black; text-shadow: white 1px 1px;" (<h2> "I'm sincerely sorry."))))))

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
          (user-pw user (call-with-output-digest (sha512-primitive) (cut display (->string u-pw) <>))))
      (redirect-to (++ "/" club "/clubbers/attendance?message=account-settings-update-successful")))))

(define-awana-app-page (regexp "/[^/]*/account-settings")
  (lambda (path)
    (let ((club (get-club path))
          (user ($session 'user)))
      (++ (<div> class: "grid_12 column-header"
                 (<div> class: "padding" "My Info"))
          (<div> class: "grid_12 column-body"
                 (<div> class: "padding"
                        (<form> action: (++ "/" club "/account-settings-trampoline") method: "POST"
                                autocomplete: "off"
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

;;; loaders

(define-page "/reload/index"
  (lambda ()
    (when (developer-access?)
      (++ (<a> href: "/reload/keep-the-records" "keep-the-records.scm")
          (<br>)
          (<br>)
          (<a> href: "/reload/setup" "setup.scm"))))
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