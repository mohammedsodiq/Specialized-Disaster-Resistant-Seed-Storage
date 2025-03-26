;; Inventory Management Contract
;; Documents varieties and quantities of seeds stored

;; Define data maps
(define-map seed-varieties
  { id: uint }
  {
    name: (string-ascii 100),
    species: (string-ascii 100),
    origin: (string-ascii 100),
    registered-by: principal
  }
)

(define-map seed-inventory
  {
    facility-id: uint,
    variety-id: uint
  }
  {
    quantity: uint,
    expiration-date: uint,
    last-updated: uint,
    last-updated-by: principal
  }
)

;; Define ID counter
(define-data-var next-variety-id uint u1)

;; Error codes
(define-constant err-invalid-input u1)
(define-constant err-not-found u2)
(define-constant err-insufficient-quantity u3)

;; Read-only functions
(define-read-only (get-variety (id uint))
  (map-get? seed-varieties { id: id })
)

(define-read-only (get-inventory (facility-id uint) (variety-id uint))
  (map-get? seed-inventory { facility-id: facility-id, variety-id: variety-id })
)

;; Public functions
(define-public (register-variety
    (name (string-ascii 100))
    (species (string-ascii 100))
    (origin (string-ascii 100)))

  (begin
    ;; Check inputs
    (asserts! (> (len name) u0) (err err-invalid-input))
    (asserts! (> (len species) u0) (err err-invalid-input))

    ;; Insert variety data
    (map-set seed-varieties
      { id: (var-get next-variety-id) }
      {
        name: name,
        species: species,
        origin: origin,
        registered-by: tx-sender
      }
    )

    ;; Increment variety ID counter
    (var-set next-variety-id (+ (var-get next-variety-id) u1))

    ;; Return success with variety ID
    (ok (- (var-get next-variety-id) u1))
  )
)

(define-public (add-inventory
    (facility-id uint)
    (variety-id uint)
    (quantity uint)
    (expiration-date uint))

  (begin
    ;; Check inputs
    (asserts! (> quantity u0) (err err-invalid-input))
    (asserts! (> expiration-date block-height) (err err-invalid-input))
    (asserts! (is-some (get-variety variety-id)) (err err-not-found))

    ;; Get existing inventory if any
    (let ((existing-inventory (get-inventory facility-id variety-id)))
      (if (is-some existing-inventory)
        (let ((current (unwrap-panic existing-inventory)))
          ;; Update existing inventory
          (map-set seed-inventory
            { facility-id: facility-id, variety-id: variety-id }
            {
              quantity: (+ (get quantity current) quantity),
              expiration-date: expiration-date,
              last-updated: block-height,
              last-updated-by: tx-sender
            }
          )
        )
        ;; Insert new inventory
        (map-set seed-inventory
          { facility-id: facility-id, variety-id: variety-id }
          {
            quantity: quantity,
            expiration-date: expiration-date,
            last-updated: block-height,
            last-updated-by: tx-sender
          }
        )
      )
    )

    ;; Return success
    (ok true)
  )
)

(define-public (remove-inventory
    (facility-id uint)
    (variety-id uint)
    (quantity uint))

  (let ((existing-inventory (unwrap! (get-inventory facility-id variety-id) (err err-not-found))))
    ;; Check inputs
    (asserts! (> quantity u0) (err err-invalid-input))
    (asserts! (>= (get quantity existing-inventory) quantity)
      (err err-insufficient-quantity))

    ;; Update inventory
    (map-set seed-inventory
      { facility-id: facility-id, variety-id: variety-id }
      {
        quantity: (- (get quantity existing-inventory) quantity),
        expiration-date: (get expiration-date existing-inventory),
        last-updated: block-height,
        last-updated-by: tx-sender
      }
    )

    ;; Return success
    (ok true)
  )
)

