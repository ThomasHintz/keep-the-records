; included in keep-the-records.scm

(use striped-zebra)

(include "config/stripe-username.scm")

(define-page "/add-account"
  (lambda ()
    (let ((response (vector->list (add-customer ($ 'stripeToken) email: ($ 'email) plan: ($ 'plan)))))
      (stripe-customer-id ($ 'email) (assoc 'id response)))
    (handle-exceptions
     exn
     'error
     (send-mail from: "momentum@keeptherecords.com" from-name: "Momentum"
		to: "momentum@keeptherecords.com" reply-to: "momentum@keeptherecords.com"
		subject: "New account added!"
		html: (++ "Good work!\n\n" ($ 'email) " is now on the " ($ 'plan) " plan.")))
    (redirect-to "/club/register-successful"))
  method: 'POST
  no-session: #t)

(define-awana-app-page "/club/register-successful"
  (lambda ()
    (<div> class: "grid_12"
	   (<h1> class: "action" "Success!")
	   "I hope you enjoy Keep the Records!"
	   (<br>)
	   (<br>)
	   (<a> href: "/user/login/" "login")))
  title: "Payment successful - KtR"
  tab: 'none
  css: '("/css/club-register.css?v=3")
  no-session: #t)

(define plan-details
  (make-parameter
   '((free . ((price . 0) (clubbers . 30)))
     (basic . ((price . 19.99) (clubbers . 75)))
     (plus . ((price . 34.99) (clubbers . 150)))
     (premier . ((price . 59.99) (clubbers . 300)))
     (ultimate . ((price . 99.99) (clubbers . "infinite"))))))

(define (get-plan plan plans) (cdr (assoc plan plans)))

(define (plan-price plan plans)
  (cdr (assoc 'price (get-plan plan plans))))

(define (plan-clubbers plan plans)
  (cdr (assoc 'clubbers (get-plan plan plans))))

(define-awana-app-page (regexp "/sign-up/payment/(free|basic|plus|premier|ultimate)")
  (lambda (path)
    (add-javascript "Stripe.setPublishableKey('pk_ms18MuOPFfilAzWkJCZG9TfXqBCV5');")
    (let ((plan (third (string-split path "/"))))
      (++ (<div> class: "grid_12"
		 (<h1> class: "action" "Sign up for Keep the Records"))
	  (<div> class: "clear")
	  (<div> class: "grid_6 column-header"
		 (<div> class: "padding" "Payment Details"))
	  (<div> class: "grid_6 column-header column-header-grey"
		 (<div> class: "padding" (++ (string-upcase plan) " Plan")))
	  (<div> class: "grid_6 column-body"
		 (<div> class: "padding"
			(<div> class: "payment-errors")
			(<form> action: "/add-account" method: "POST" id: "payment-form"
				(<input> type: "hidden" name: "plan" value: plan) (<br>)
				(<span> class: "form-context" "Full Name") (<br>)
				(<input> type: "text" size: "20" class: "card-name text") (<br>)
				(<span> class: "form-context" "Email") (<br>)
				(<input> type: "text" class: "email text" name: "email" value: ($ 'email)) (<br>)
				(<span> class: "form-context" "Credit Card Number") (<br>)
				(<input> type: "text" size: "20" autocomplete: "off" class: "card-number text") (<br>)
				(<span> class: "form-context" "Credit Card CVC")
				(<br>)
				(<input> type: "text" style: "width: 80px;" autocomplete: "off" class: "card-cvc text")
				(<span> class: "form-context" "3 or 4 digits on back of card")
				(<br>)
				(<span> class: "form-context" "Credit Card Expiration (MM/YYYY)") (<br>)
				(<input> type: "text" style: "width: 80px;" class: "card-expiry-month text")
				(<span> class: "form-context" "/")
				(<input> type: "text" style: "width: 169px;" class: "card-expiry-year text") (<br>)
				(<button> type: "submit" class: "submit-button button button-blue" "Submit Payment"))))
	  (<div> class: "grid_6 column-body"
		 (<div> class: "padding"
			(<div> class: "plan-features"
			       (itemize `(,(++ "$" (->string (plan-price (string->symbol plan) (plan-details))) " / month")
					  ,(++ (->string (plan-clubbers (string->symbol plan) (plan-details))) " clubbers")
					  ,"No questions asked, 30 day money back guarantee")))
			(<br>) (<br>)
			(<div> class: "plan-aside"
			       "We use a secure, encrypted connection to transfer your credit card number straight to the bank. Neither we nor anyone else ever sees it."
			       (<br>) (<br>)
			       "You can cancel or upgrade anytime."
			       (<br>) (<br>)
			       "You can add more clubbers than your plan allows, but you will be required to upgrade your plan before the next billing period."))))))
  css: '("/css/club-register.css?v=3")
  no-ajax: #f
  title: "Payment details - KtR"
  tab: 'none
  no-session: #t
  headers: (++ (include-javascript "https://js.stripe.com/v1/")
	       (include-javascript "/js/payments.js")))
