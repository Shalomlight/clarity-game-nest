;; GameNest - Decentralized Gaming Communities Hub

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-proposal-expired (err u105))
(define-constant err-transfer-failed (err u106))

;; Data Variables
(define-data-var next-community-id uint u0)
(define-data-var next-proposal-id uint u0)
(define-data-var proposal-duration uint u144)

;; [Previous map definitions remain unchanged...]

;; Enhanced Treasury Management
(define-public (deposit-to-treasury (community-id uint) (amount uint))
    (let
        (
            (community (unwrap! (map-get? communities community-id) err-not-found))
            (member (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) err-unauthorized))
            (transfer-result (stx-transfer? amount tx-sender (as-contract tx-sender)))
        )
        (asserts! (is-ok transfer-result) err-transfer-failed)
        (map-set communities community-id 
            (merge community { treasury-balance: (+ (get treasury-balance community) amount) })
        )
        (update-member-points community-id tx-sender u10)
        (ok true)
    )
)

;; Helper function for member points
(define-private (update-member-points (community-id uint) (member-principal principal) (points uint))
    (let
        (
            (member (unwrap! (map-get? community-members { community-id: community-id, member: member-principal }) err-not-found))
        )
        (map-set community-members 
            { community-id: community-id, member: member-principal }
            (merge member { 
                points: (+ (get points member) points),
                last-action: block-height 
            })
        )
    )
)

;; Enhanced Voting with Improved Weight Calculation
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
            (member (unwrap! (map-get? community-members { community-id: (get community-id proposal), member: tx-sender }) err-unauthorized))
            (vote-weight (+ u100 (get reputation member)))
            (weighted-vote (/ (* vote-weight u100) u100))
        )
        (asserts! (<= block-height (get expires-at proposal)) err-proposal-expired)
        (if vote
            (map-set proposals proposal-id (merge proposal { votes-for: (+ (get votes-for proposal) weighted-vote) }))
            (map-set proposals proposal-id (merge proposal { votes-against: (+ (get votes-against proposal) weighted-vote) }))
        )
        (update-member-points (get community-id proposal) tx-sender u5)
        (ok true)
    )
)

;; [Previous functions remain unchanged...]
