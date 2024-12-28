;; GameNest - Decentralized Gaming Communities Hub

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))

;; Data Variables
(define-data-var next-community-id uint u0)
(define-data-var next-proposal-id uint u0)

;; Data Maps
(define-map communities
    uint
    {
        name: (string-ascii 50),
        description: (string-ascii 500),
        owner: principal,
        treasury-balance: uint,
        total-members: uint,
        created-at: uint
    }
)

(define-map community-members
    { community-id: uint, member: principal }
    {
        points: uint,
        joined-at: uint,
        role: (string-ascii 20)
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
        created-at: uint
    }
)

;; Public Functions

;; Create a new gaming community
(define-public (create-community (name (string-ascii 50)) (description (string-ascii 500)))
    (let
        (
            (community-id (var-get next-community-id))
        )
        (map-insert communities community-id {
            name: name,
            description: description,
            owner: tx-sender,
            treasury-balance: u0,
            total-members: u1,
            created-at: block-height
        })
        (map-insert community-members 
            { community-id: community-id, member: tx-sender }
            {
                points: u100,
                joined-at: block-height,
                role: "owner"
            }
        )
        (var-set next-community-id (+ community-id u1))
        (ok community-id)
    )
)

;; Join a community
(define-public (join-community (community-id uint))
    (let
        (
            (community (unwrap! (map-get? communities community-id) err-not-found))
        )
        (if (map-get? community-members { community-id: community-id, member: tx-sender })
            err-already-exists
            (begin
                (map-insert community-members 
                    { community-id: community-id, member: tx-sender }
                    {
                        points: u0,
                        joined-at: block-height,
                        role: "member"
                    }
                )
                (map-set communities community-id 
                    (merge community { total-members: (+ (get total-members community) u1) })
                )
                (ok true)
            )
        )
    )
)

;; Create a community proposal
(define-public (create-proposal (community-id uint) (title (string-ascii 100)) (description (string-ascii 500)))
    (let
        (
            (proposal-id (var-get next-proposal-id))
            (member (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) err-unauthorized))
        )
        (map-insert proposals proposal-id {
            community-id: community-id,
            title: title,
            description: description,
            proposer: tx-sender,
            votes-for: u0,
            votes-against: u0,
            status: "active",
            created-at: block-height
        })
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
    )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
    (let
        (
            (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
            (member (unwrap! (map-get? community-members { community-id: (get community-id proposal), member: tx-sender }) err-unauthorized))
        )
        (if vote
            (map-set proposals proposal-id (merge proposal { votes-for: (+ (get votes-for proposal) u1) }))
            (map-set proposals proposal-id (merge proposal { votes-against: (+ (get votes-against proposal) u1) }))
        )
        (ok true)
    )
)

;; Award points to a community member
(define-public (award-points (community-id uint) (recipient principal) (amount uint))
    (let
        (
            (member (unwrap! (map-get? community-members { community-id: community-id, member: tx-sender }) err-unauthorized))
            (recipient-data (unwrap! (map-get? community-members { community-id: community-id, member: recipient }) err-not-found))
        )
        (if (is-eq (get role member) "owner")
            (begin
                (map-set community-members 
                    { community-id: community-id, member: recipient }
                    (merge recipient-data { points: (+ (get points recipient-data) amount) })
                )
                (ok true)
            )
            err-unauthorized
        )
    )
)

;; Read-only functions

(define-read-only (get-community-info (community-id uint))
    (ok (map-get? communities community-id))
)

(define-read-only (get-member-info (community-id uint) (member principal))
    (ok (map-get? community-members { community-id: community-id, member: member }))
)

(define-read-only (get-proposal-info (proposal-id uint))
    (ok (map-get? proposals proposal-id))
)