;; Access Protocol Contract
;; Manages seed distribution after disasters

;; Define data maps
(define-map disaster-events
  { id: uint }
  {
    name: (string-ascii 100),
    region: (string-ascii 100),
    severity: uint,
    start-date: uint,
    end-date: (optional uint),
    declared-by: principal,
    active: bool
  }
)

(define-map distribution-requests
  { id: uint }
  {
    event-id: uint,
    requester: principal,
    facility-id: uint,
    variety-id: uint,
    quantity: uint,
    purpose: (string-ascii 100),
    status: (string-ascii 10),
    approved-by: (optional principal)
  }
)

(define-map authorizers
  { address: principal }
  { active: bool }
)

;; Define ID counters
(define-data-var next-event-id uint u1)
(define-data-var next-request-id uint u1)

;; Error codes
(define-constant err-not-authorized u1)
(define-constant err-invalid-input u2)
(define-constant err-not-found u3)
(define-constant err-invalid-state u4)

;; Read-only functions
(define-read-only (get-event (id uint))
  (map-get? disaster-events { id: id })
)

(define-read-only (get-request (id uint))
  (map-get? distribution-requests { id: id })
)

(define-read-only (is-authorizer (address principal))
  (default-to false (get active (map-get? authorizers { address: address })))
)

;; Public functions
(define-public (declare-event
    (name (string-ascii 100))
    (region (string-ascii 100))
    (severity uint))

  (begin
    ;; Check authorization
    (asserts! (is-authorizer tx-sender) (err err-not-authorized))

    ;; Check inputs
    (asserts! (> (len name) u0) (err err-invalid-input))
    (asserts! (> (len region) u0) (err err-invalid-input))
    (asserts! (<= severity u5) (err err-invalid-input))

    ;; Insert event data
    (map-set disaster-events
      { id: (var-get next-event-id) }
      {
        name: name,
        region: region,
        severity: severity,
        start-date: block-height,
        end-date: none,
        declared-by: tx-sender,
        active: true
      }
    )

    ;; Increment event ID counter
    (var-set next-event-id (+ (var-get next-event-id) u1))

    ;; Return success with event ID
    (ok (- (var-get next-event-id) u1))
  )
)

(define-public (end-event (id uint))
  (let ((event (unwrap! (get-event id) (err err-not-found))))
    ;; Check authorization
    (asserts! (or
      (is-eq tx-sender (get declared-by event))
      (is-authorizer tx-sender))
      (err err-not-authorized))

    ;; Check event is active
    (asserts! (get active event) (err err-invalid-state))

    ;; Update event
    (map-set disaster-events
      { id: id }
      (merge event {
        end-date: (some block-height),
        active: false
      })
    )

    ;; Return success
    (ok true)
  )
)

(define-public (request-distribution
    (event-id uint)
    (facility-id uint)
    (variety-id uint)
    (quantity uint)
    (purpose (string-ascii 100)))

  (let ((event (unwrap! (get-event event-id) (err err-not-found))))
    ;; Check event is active
    (asserts! (get active event) (err err-invalid-state))

    ;; Check inputs
    (asserts! (> quantity u0) (err err-invalid-input))
    (asserts! (> (len purpose) u0) (err err-invalid-input))

    ;; Insert request
    (map-set distribution-requests
      { id: (var-get next-request-id) }
      {
        event-id: event-id,
        requester: tx-sender,
        facility-id: facility-id,
        variety-id: variety-id,
        quantity: quantity,
        purpose: purpose,
        status: "PENDING",
        approved-by: none
      }
    )

    ;; Increment request ID counter
    (var-set next-request-id (+ (var-get next-request-id) u1))

    ;; Return success with request ID
    (ok (- (var-get next-request-id) u1))
  )
)

(define-public (approve-request (id uint))
  (let ((request (unwrap! (get-request id) (err err-not-found))))
    ;; Check authorization
    (asserts! (is-authorizer tx-sender) (err err-not-authorized))

    ;; Check request is pending
    (asserts! (is-eq (get status request) "PENDING") (err err-invalid-state))

    ;; Update request
    (map-set distribution-requests
      { id: id }
      (merge request {
        status: "APPROVED",
        approved-by: (some tx-sender)
      })
    )

    ;; Return success
    (ok true)
  )
)

(define-public (reject-request (id uint))
  (let ((request (unwrap! (get-request id) (err err-not-found))))
    ;; Check authorization
    (asserts! (is-authorizer tx-sender) (err err-not-authorized))

    ;; Check request is pending
    (asserts! (is-eq (get status request) "PENDING") (err err-invalid-state))

    ;; Update request
    (map-set distribution-requests
      { id: id }
      (merge request {
        status: "REJECTED",
        approved-by: (some tx-sender)
      })
    )

    ;; Return success
    (ok true)
  )
)

(define-public (add-authorizer (address principal))
  (begin
    ;; Add authorizer
    (map-set authorizers
      { address: address }
      { active: true }
    )

    ;; Return success
    (ok true)
  )
)

(define-public (remove-authorizer (address principal))
  (begin
    ;; Update authorizer status
    (map-set authorizers
      { address: address }
      { active: false }
    )

    ;; Return success
    (ok true)
  )
)

