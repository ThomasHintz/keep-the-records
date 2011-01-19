;;; WARNING user/club names should be cleaned, null and / are illegal characters

(require-extension awful message-digest-port sha2 posix http-session spiffy-cookies html-tags html-utils srfi-13 srfi-19 regex srfi-69 doctype http-session)

;;; Settings

(enable-ajax #t)
(ajax-library "http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")
(enable-session #t)
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
                           (<a> href: "/account-settings" "My Info") " | "
                           (<a> href: "/sign-out" "Signout"))
                        "")
                    (if (not (eq? tab 'none))
                        (<div> class: "grid_12 menu-bar full-width"
                               (<a> class: (++ "main-menu-item" (if (eq? tab 'club-night) " main-menu-item-current" ""))
                                    href: (++ "/" club "/club-night/attendance") "Club Night")
                               (<a> class: (++ "main-menu-item" (if (eq? tab 'stats) " main-menu-item-current" ""))
                                    href: (++ "/" club "/stats/attendance") "Stats")
                               (<a> class: (++ "main-menu-item" (if (eq? tab 'admin) " main-menu-item-current" ""))
                                    href: (++ "/" club "/admin/leader-access") "Admin"))
                        "")
                    (<div> class: "grid_12 main-tab-bar full-width"
                           (cond
                            ((eq? tab 'club-night)
                             (++ (<a> href: (++ "/" club "/club-night/attendance")
                                      class: (main-tab-class (is-current?
                                                              (++ "/" club "/club-night/attendance") actual-path))
                                      "Attendance")
                                 (<a> href: (++ "/" club "/club-night/clubbers")
                                      class: (main-tab-class (is-current? (++ "/" club "/club-night/clubbers") actual-path))
                                      "Clubbers")
                                 (<a> href: (++ "/" club "/club-night/sections")
                                      class: (main-tab-class (is-current? (++ "/" club "/club-night/sections") actual-path))
                                      "Sections")
                                 (<a> href: (++ "/" club "/club-night/allergies")
                                      class: (main-tab-class (is-current? (++ "/" club "/club-night/allergies") actual-path))
                                      "Allergies")
                                 (<a> href: (++ "/" club "/club-night/release")
                                      class: (main-tab-class (is-current? (++ "/" club "/club-night/release") actual-path))
                                      "Release")))
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
                             (++ (<a> href: (++ "/" club "/admin/leader-access")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/admin/leader-access") actual-path))
                                      "Leader Access")
                                 (<a> href: (++ "/" club "/admin/club")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/admin/club") actual-path))
                                      "Club")
                                 (<a> href: (++ "/" club "/admin/clubbers")
                                      class: (main-tab-class
                                              (is-current? (++ "/" club "/admin/clubbers") actual-path))
                                      "Clubbers")))
                            ((eq? tab 'none) "")))
                    (<div> class: "selected-tab-container" (if (regexp? path) (content actual-path) (content))))))))
    css: (append '("http://fonts.googleapis.com/css?family=Tangerine:regular,bold&subset=latin"
                   "http://fonts.googleapis.com/css?family=Neucha&subset=latin"
                   "http://fonts.googleapis.com/css?family=Josefin+Sans+Std+Light"
                   "http://fonts.googleapis.com/css?family=Vollkorn&subset=latin"
                   "/css/reset.css" "/css/960.css" "/css/master.css?ver=0") css)
    title: title
    no-session: no-session
    no-ajax: no-ajax
    headers: (++ (insert-file "analytics.html") headers)
    doctype: doctype-html))

;;; development reload

(define-page "/reloadme"
  (lambda ()
    ;(ajax "reloadme" 'reloadme 'click
    ;      (lambda ()
    ;        (load-apps (awful-apps))
    ;        "Reloaded")
    ;      target: "result-div"
    ;      no-session: #t)
    ;(++ (<input> id: "reloadme" type: "button" value: "Reload Apps")
    ;    (<div> id: "result-div")))
    (load-apps (awful-apps))
    "Reloaded")
  no-session: #t
  no-ajax: #f)

;;; club/user create

(define-awana-app-page "/club/register"
  (lambda ()
    (add-javascript "$(document).ready(function() { $('#church').focus(); });")
    (<div> class: "grid_12"
           (<form> action: "/club/create" method: "post"
                   (<h1> class: "action" "Create Club")
                   (<span> class: "form-context" "Church or Association Name")
                   (<br>)
                   (<input> class: "text" type: "text" id: "church" name: "church")
                   (<h1> class: "action" "Create Your Account")
                   (<span> class: "form-context" "Name")
                   (<br>)
                   (<input> class: "text" type: "text" id: "name" name: "name")
                   (<br>)
                   (<span> class: "form-context" "Email")
                   (<br>)
                   (<input> class: "text" type: "text" id: "email" name: "email")
                   (<br>)
                   (<span> class: "form-context" "Password")
                   (<br>)
                   (<input> class: "text" type: "password" id: "password" name: "password")
                   (<br>)
                   (<span> class: "form-context" "Password Again")
                   (<br>)
                   (<input> class: "text" type: "password" id: "password-again" name: "password-again")
                   (<br>)
                   (<input> type: "submit" value: "Create Club" class: "create"))))
  css: '("/css/club-register.css?v=1")
  no-ajax: #f
  no-session: #t
  tab: 'none)

;;; user login/create

(define-awana-app-page "/user/register"
  (lambda ()
    (let ((attempted-path ($ 'attempted-path)))
      (++ (<h1> "Register Yourself")
          (<form> action: "/user/create" method: "post"
                  (if attempted-path
                      (hidden-input 'attempted-path attempted-path)
                      "")
                  (<table> class: "user-register"
                           (<tr> (<td> "Name:")
                                 (<td> (<input> type: "text" id: "name" name: "name")))
                           (<tr> (<td> "Email:")
                                 (<td> (<input> type: "text" id: "email" name: "email")))
                           (<tr> (<td> "Club:")
                                 (<td> (<input> type: "text" id: "club" name: "club")))
                           (<tr> (<td> "Password:")
                                 (<td> (<input> type: "password" id: "password" name: "password"))
                                 (<td> "Password Again:")
                                 (<td> (<input> type: "password" id: "password-again" name: "password-again")))
                           (<tr> (<td> (<input> type: "submit" id: "register-submit" value: "Submit"))))))))
  css: '("/css/user-register.css")
  no-session: #t)

(define (password-matches? user password)
  (string=? (call-with-output-digest (sha512-primitive) (cut display password <>))
            (user-pw user)))

(define-awana-app-page "/user/create"
  (lambda ()
    (let ((name ($ 'name))
          (email ($ 'email))
          (club ($ 'club))
          (password ($ 'password))
          (password-again ($ 'password-again))
          (attempted-path ($ 'attempted-path)))
      (if (string=? password password-again)
          (begin (user-name email name)
                 (user-pw email (call-with-output-digest (sha512-primitive) (cut display (->string password) <>)))
                 (user-email email email))
          (html-page
           ""
           headers: (<meta> http-equiv: "refresh"
                            content: (++ "0;url=/user/register?reason=passwords-dont-match&user=" email))))))
  no-session: #t)

(define-login-trampoline "/login-trampoline"
  hook: (lambda (user)
          ($session-set! 'user user)
          ($session-set! 'club (user-club user))))

(login-page-path "/user/login")
(define-awana-app-page (login-page-path)
  (lambda ()
    (login-form))
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
                          content: (++ "0;url=/" (user-club u-name) "/club-night/attendance"))))))
  no-session: #t)

;;; club pages

(define-awana-app-page "/club/create"
  (lambda ()
    (let* ((church ($ 'church))
           (club (as-db-unique (lambda (c) (club-name c)) (name->id church) 0))
           (u-name ($ 'name))
           (u-email ($ 'email))
           (u-pw ($ 'password))
           (u-pw2 ($ 'password-again)))
      (if (and (string=? u-pw u-pw2) (eq? (user-name u-email) 'not-found))
          (begin (club-name club church)
                 (user-name u-email u-name)
                 (user-club u-email club)
                 (user-email u-email u-email)
                 (user-pw u-email (call-with-output-digest (sha512-primitive) (cut display (->string u-pw) <>)))
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

(define-awana-app-page (regexp "/[^/]*/club-night/clubbers/register")
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
      (++ (<div> class: "grid_12" (<div> class: "success" id: "success" (if ($ 'success) "Clubber Added Successfully" "")))
          (<div> class: "grid_6" (<div> class: "padding column-header" "Register New Clubber"))
          (<div> class: "clear clear-no-space")
          (<div> class: "grid_6"
                 (<div> class: "padding column-body"
                        (<form> action: (++ "/" club  "/club-night/clubbers/create" (if ($ 'from) (++ "?from=" ($ 'from)) ""))
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
  css: '("/css/add-clubber.css" "/css/autocomplete.css")
  headers: (++ (include-javascript "/js/add-clubber.js") (include-javascript "/js/autocomplete.js"))
  no-ajax: #f
  tab: 'club-night
  title: "Register Clubber - Club Night - KtR")

(define-awana-app-page (regexp "/[^/]*/club-night/clubbers/create")
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
                                           (cons ($ 'name) children)))))
      (html-page
       ""
       headers: (<meta> http-equiv: "refresh"
                        content: (++ "0;url=" (if (not (eq? from #f))
                                                  from
                                                  (++ "/" club "/club-night/clubbers/register?success=true")))))))
  no-session: #t)

(define (present-clubbers club)
  (let ((today (todays-date)))
    (filter (lambda (m-name)
              (if (present club m-name today) #t #f)) (db:list "clubs" club "clubbers"))))

(define (attendees-html club)
  (let ((present-clubbers (sort (present-clubbers club) string<)))
    (++ "In Attendance: "
        (number->string (fold (lambda (m c) (+ c 1)) 0 present-clubbers))
        (<br>) (<br>)
        (fold (lambda (m-name o)
                (++ o (<a> href: (++ "/" club "/club-night/clubbers/" m-name) (name club m-name)) (<br>)))
              ""
              present-clubbers))))

(define (todays-mm) (date->string (current-date) "~m"))
(define (todays-dd) (date->string (current-date) "~d"))
(define (todays-yy) (date->string (current-date) "~y"))
(define (todays-yyyy) (date->string (current-date) "~Y"))

;;; take attendance

(define-awana-app-page (regexp "/[^/]*/club-night/attendance")
  (lambda (path)
    (let ((club (get-club path))
          (date (++ (or ($ 'year) (todays-yyyy)) "/" (or ($ 'month) (todays-mm)) "/" (or ($ 'day) (todays-dd)))))
      (ajax "clubber-attendance-info" 'clubbers '(change keypress)
            (lambda ()
              (let ((name ($ 'name)))
                (if name
                    `((clubber-name . ,name)
                      (present . ,(present club name date))
                      (bible . ,(bible club name date))
                      (handbook . ,(handbook club name date))
                      (uniform . ,(uniform club name date))
                      (friend . ,(friend club name date))
                      (points-total . ,(total-points club name))
                      (allergies . ,(allergies club name))
                      (club-level . ,(club-level club name))
                      (notes . ,(notes club name))
                      (attendees-html . ,(attendees-html club)))
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
                        (combo-box "clubbers" (map (lambda (e) (name club e)) (db:list "clubs" club "clubbers"))
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
                                      (<div> class: "points" id: "points-total")
                                      (<div> class: "points points-label" " points"))
                               (<div> class: "allergy-info" id: "allergy-container"
                                      (<div> class: "allergic-to info" "Allergic To:") (<br>)
                                      (<div> class: "allergic-to-item" id: "allergies" ""))
                               (<div> class: "notes info" id: "notes" ""))))
          (<div> class: "grid_3 column-body"
              (<div> class: "tab-body padding"
                     (<div> class: "attendees" id: "attendees"
                            (attendees-html club)))))))
  headers: (include-javascript "/js/attendance.js")
  no-ajax: #f
  css: '("/css/attendance.css?ver=2")
  tab: 'club-night
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
                       (string< (second (string-split (name club e1) " "))
                                (second (string-split (name club e2) " ")))
                       (string< e1 e2)))))

(define (clubbers->names club clubbers)
  (map (lambda (clubber)
         (name club clubber))
       clubbers))

(define (clubbers->urls club clubbers first-name-first)
  (fold (lambda (e o)
          (++ o (<a> class: "clubber-url" href: (++ "/" club "/club-night/clubbers/" e)
                     (++ (if first-name-first
                             (name club e)
                             (++ (second (string-split (name club e) " ")) " "
                                 (first (string-split (name club e) " "))))
                         (<br>)))))
        ""
        clubbers))

(define-awana-app-page (regexp "/[^/]*/club-night/clubbers")
  (lambda (path)
    (let ((club (get-club path))
          (search ($ 'search))
          (sort-value ($ 'sort)))
      (++ (<div> class: "grid_4 small-title"
                 (<form> action: path method: "GET"
                         "Search: "
                         (<input> type: "text" id: "search" name: "search" class: "search"
                                  value: (if search search ""))))
          (<div> class: "grid_4 small-title"
                 "Sort By"
                 (<a> href: (++ path "?sort=first" (if search (++ "&search=" search) ""))
                      class: (++ "sort-link"
                                 (if (or (not sort-value) (and sort-value (string=? sort-value "first")))
                                     " current-sort" "")) "First Name")
                 (<a> href: (++ path "?sort=last" (if search (++ "&search=" search) ""))
                      class: (++ "sort-link"
                                 (if (and sort-value (string=? sort-value "last"))
                                     " current-sort" "")) "Last Name"))
          (<div> class: "grid_4 small-title"
                 (<span> class: "new-clubber-symbol" "+ ")
                 (<a> href: (++ "/" club "/club-night/clubbers/register") class: "new-clubber" "Add New Clubber"))
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
  tab: 'club-night
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

(define-awana-app-page (regexp "/[^/]*/club-night/clubbers/[^/]*")
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
                                      (total-points club clubber) " points"))
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
  tab: 'club-night
  title: "Clubber Info - Club Night - KtR")

;;; watch list

(define (allergy-filter club clubbers)
  (filter (lambda (e) (if (not (string=? (allergies club e) "")) #t #f)) clubbers))

(define (clubbers->allergy-box club clubbers first-name-first)
  (fold (lambda (e o)
          (++ o
              (<a> class: "clubber-url" href: (++ "/" club "/club-night/clubbers/" e)
                   (if first-name-first
                       (name club e)
                       (++ (second (string-split (name club e) " ")) " "
                           (first (string-split (name club e) " ")))))
              (<br>)
              (<div> class: "allergies" (allergies club e))
              (<br>)))
        ""
        clubbers))

(define-awana-app-page (regexp "/[^/]*/club-night/allergies")
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
  tab: 'club-night
  title: "Allergies - Club Night - KtR")

;;; discharge

(define (reverse-name name)
  (let ((n (string-split name " ")))
    (++ (second n) " " (first n))))

(define-page (regexp "/[^/]*/club-night/release/awana-release-form")
  (lambda (path)
    (let ((club (get-club path)))
      (define-pdf (++ "/" club "/club-night/release/awana-release-form-" club "-"
                      (date->string (current-date) "~m~d~y") ".pdf")
        (lambda ()
          (pdf-release-form (map reverse-name (clubbers->names club (name-sort club (present-clubbers club) "last")))
                            (++ club "-awana-release-form.pdf"))
          (insert-file (++ club "-awana-release-form.pdf"))))
      (redirect-to (++ "/" club "/club-night/release/awana-release-form-" club "-"
                       (date->string (current-date) "~m~d~y") ".pdf")))))

(define-awana-app-page (regexp "/[^/]*/club-night/release")
  (lambda (path)
    (let ((club (get-club path)))
      (++ (<div> class: "grid_12 column-body" (<div> class: "padding"
                                                     (<a> href: (++ "/" club "/club-night/release/awana-release-form")
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
                                    (<a> class: "name" href: (++ "/" club "/club-night/clubbers/" (fourth clubber-pair))
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
  tab: 'club-night
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

(define-awana-app-page (regexp "/[^/]*/club-night/sections")
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
  tab: 'club-night)

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

(define-awana-app-page (regexp "/[^/]*/admin/leader-access")
  (lambda (path)
    (++ (<div> class: "grid_6"
               (<div> class: "padding column-header" "Grant Access To Leader")
               (<div> class: "padding column-body"
                      (<span> class: "context" "Leader's Email Address")
                      (<br>)
                      (<input> class: "email" id: "email" name: "email")
                      (<br>)
                      (<div> class: "email-desc" "An email will be sent to the above address with a link that will allow this person to access this organization's Awana records. They will have full access to do anything, so be careful.")
                      (<input> class: "send-email" type: "submit" value: "Send Access Email")))
        (<div> class: "grid_6"
               (<div> class: "padding column-header" "Leaders With Access")
               (<div> class: "padding column-body"
                      (<div> class: "leader-name" "Joe Bixley")
                      (<div> class: "leader-name" "John Smith")
                      (<div> class: "leader-name" "Alice Romley")))))
  css: '("/css/leader-access.css?v=0")
  tab: 'admin
  title: "Leader Access - KtR")

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

;;; main app pages

(define-page "/"
  (lambda ()
    (redirect-to (++ "/" (name->id (user-club ($session 'user))) "/club-night/attendance"))))

(define-awana-app-page (regexp "/[^/]*/first-use")
  (lambda (path)
    "yup")
  title: "First Use - KtR")

(define-awana-app-page "/testses"
  (lambda () (++ "user: " ($session 'user))))