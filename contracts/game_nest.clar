;; GameNest - Decentralized Gaming Communities Hub

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-proposal-expired (err u105))

;; Data Variables
(define-data-var next-community-id uint u0)
(define-data-var next-proposal-id uint u0)

;; Configuration
(define-data-var proposal-duration uint u144) ;; ~1 day in blocks

;; Data Maps
(define-map communities
    uint
    {
        name: (string-ascii 50),
        description: (string-ascii 500),
        owner: principal,
        treasury-balance: uint,
        total-members: uint,
        created-at: uint,
        reputation-threshold: uint
    }
)

(define-map community-members
    { community-id: uint, member: principal }
    {
        points: uint,
        reputation: uint,
        joined-at: uint,
        role: (string-ascii 20),
        last-action: uint
    }
)

(define-map proposals
    uint 
    {
        community-id: uint,
        title: (string-ascii 100),
        description: (string-ascii 500),
        proposer: principal,
        votes-for: uint,
        votes-against: uint,
        status: (string-ascii 20),
        created-at: uint,
        expires-at: uint,
        executed: bool
    }
)

;; Treasury Management
(define-public (deposit-to-treasury (community-id uint) (amount uint))
    (let
        (
            (community (unwrap! (map-get? communities community-id) err-not-found))
            (member (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) err-unauthorized))
        )
        (map-set communities community-id 
            (merge community { treasury-balance: (+ (get treasury-balance community) amount) })
        )
        (ok true)
    )
)

(define-public (withdraw-from-treasury (community-id uint) (amount uint))
    (let
        (
            (community (unwrap! (map-get? communities community-id) err-not-found))
            (member (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) err-unauthorized))
        )
        (asserts! (is-eq (get role member) "owner") err-unauthorized)
        (asserts! (<= amount (get treasury-balance community)) err-invalid-amount)
        (map-set communities community-id 
            (merge community { treasury-balance: (- (get treasury-balance community) amount) })
        )
        (ok true)
    )
)

;; Enhanced Proposal Management
(define-public (execute-proposal (proposal-id uint))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
            (community (unwrap! (map-get? communities (get community-id proposal)) err-not-found))
            (current-height block-height)
        )
        (asserts! (not (get executed proposal)) err-already-exists)
        (asserts! (<= current-height (get expires-at proposal)) err-proposal-expired)
        (asserts! (> (get votes-for proposal) (get votes-against proposal)) err-unauthorized)
        
        (map-set proposals proposal-id (merge proposal { executed: true }))
        (ok true)
    )
)

;; Enhanced Voting with Weight
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
            (member (unwrap! (map-get? community-members { community-id: (get community-id proposal), member: tx-sender }) err-unauthorized))
            (vote-weight (+ u1 (/ (get reputation member) u100)))
        )
        (asserts! (<= block-height (get expires-at proposal)) err-proposal-expired)
        (if vote
            (map-set proposals proposal-id (merge proposal { votes-for: (+ (get votes-for proposal) vote-weight) }))
            (map-set proposals proposal-id (merge proposal { votes-against: (+ (get votes-against proposal) vote-weight) }))
        )
        (ok true)
    )
)

;; [Previous functions remain unchanged...]
