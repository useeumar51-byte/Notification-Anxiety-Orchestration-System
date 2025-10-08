;; Deep Work Disruption Engine Smart Contract
;; Ensures you receive a Slack notification exactly 30 seconds into any meaningful thought
;;
;; This contract coordinates perfectly-timed interruptions to maximize attention fragmentation
;; and cognitive load disruption through sophisticated timing and tracking mechanisms.

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-PARAMS (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INSUFFICIENT-FOCUS (err u104))
(define-constant ERR-DISRUPTION-LIMIT-REACHED (err u105))
(define-constant MAX-DISRUPTIONS-PER-SESSION u50)
(define-constant OPTIMAL-DISRUPTION-TIME u30) ;; 30 seconds
(define-constant MAX-INTENSITY u10)
(define-constant MIN-FOCUS-THRESHOLD u5)

;; Data Variables
(define-data-var total-sessions uint u0)
(define-data-var total-disruptions uint u0)
(define-data-var system-enabled bool true)
(define-data-var global-disruption-multiplier uint u1)
(define-data-var last-maintenance-block uint u0)

;; Data Maps
(define-map work-sessions 
    { session-id: uint }
    {
        user: principal,
        start-time: uint,
        focus-level: uint,
        disruption-count: uint,
        is-active: bool,
        target-thoughts: (list 10 (string-ascii 100)),
        session-type: (string-ascii 50)
    }
)

(define-map disruption-patterns
    { pattern-id: uint }
    {
        name: (string-ascii 100),
        trigger-time: uint,
        intensity: uint,
        platform: (string-ascii 50),
        message-template: (string-ascii 200),
        success-rate: uint,
        created-by: principal
    }
)

(define-map user-disruption-stats
    { user: principal }
    {
        total-sessions: uint,
        successful-disruptions: uint,
        average-focus-time: uint,
        preferred-platform: (string-ascii 50),
        disruption-sensitivity: uint,
        last-session: uint
    }
)

(define-map scheduled-interruptions
    { interruption-id: uint }
    {
        session-id: uint,
        scheduled-time: uint,
        intensity: uint,
        status: (string-ascii 20),
        platform: (string-ascii 50),
        execution-block: uint
    }
)

;; Read-only functions for data retrieval
(define-read-only (get-session-info (session-id uint))
    (map-get? work-sessions { session-id: session-id })
)

(define-read-only (get-disruption-pattern (pattern-id uint))
    (map-get? disruption-patterns { pattern-id: pattern-id })
)

(define-read-only (get-user-stats (user principal))
    (map-get? user-disruption-stats { user: user })
)

(define-read-only (get-total-sessions)
    (var-get total-sessions)
)

(define-read-only (get-total-disruptions)
    (var-get total-disruptions)
)

(define-read-only (is-system-enabled)
    (var-get system-enabled)
)

(define-read-only (calculate-optimal-disruption-time (focus-level uint))
    (let ((base-time OPTIMAL-DISRUPTION-TIME)
          (adjustment (if (> focus-level u8) u10 u0)))
        (- base-time adjustment)
    )
)

(define-read-only (get-disruption-effectiveness (session-id uint))
    (match (get-session-info session-id)
        session-data (let ((disruption-count (get disruption-count session-data))
                          (focus-level (get focus-level session-data)))
                        (if (> focus-level u0)
                            (/ (* disruption-count u100) focus-level)
                            u0))
        u0
    )
)

;; Administrative functions
(define-public (toggle-system (enabled bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set system-enabled enabled)
        (ok enabled)
    )
)

(define-public (set-global-multiplier (multiplier uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (asserts! (<= multiplier u5) ERR-INVALID-PARAMS)
        (var-set global-disruption-multiplier multiplier)
        (ok multiplier)
    )
)

;; Core disruption functions
(define-public (initialize-disruption-patterns)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (try! (create-disruption-pattern 
            u1 
            "Slack Deep Thought Killer" 
            OPTIMAL-DISRUPTION-TIME 
            u8 
            "slack" 
            "New idea brewing? Let me interrupt that for you!"
        ))
        (try! (create-disruption-pattern 
            u2 
            "Email Urgency Fabricator" 
            u45 
            u6 
            "email" 
            "URGENT: Someone breathed near your project!"
        ))
        (try! (create-disruption-pattern 
            u3 
            "Teams Meeting Ambush" 
            u20 
            MAX-INTENSITY 
            "teams" 
            "Surprise! Mandatory fun meeting in 2 minutes!"
        ))
        (ok true)
    )
)

(define-private (create-disruption-pattern 
    (pattern-id uint) 
    (name (string-ascii 100)) 
    (trigger-time uint) 
    (intensity uint) 
    (platform (string-ascii 50)) 
    (message (string-ascii 200))
    )
    (begin
        (asserts! (<= intensity MAX-INTENSITY) ERR-INVALID-PARAMS)
        (asserts! (is-none (map-get? disruption-patterns { pattern-id: pattern-id })) ERR-ALREADY-EXISTS)
        (map-set disruption-patterns
            { pattern-id: pattern-id }
            {
                name: name,
                trigger-time: trigger-time,
                intensity: intensity,
                platform: platform,
                message-template: message,
                success-rate: u0,
                created-by: tx-sender
            }
        )
        (ok pattern-id)
    )
)

(define-public (start-work-session 
    (session-id uint)
    (session-type (string-ascii 50))
    (target-thoughts (list 10 (string-ascii 100)))
    )
    (begin
        (asserts! (var-get system-enabled) (err u999))
        (asserts! (is-none (get-session-info session-id)) ERR-ALREADY-EXISTS)
        (let ((current-stats (default-to 
                    { total-sessions: u0, successful-disruptions: u0, average-focus-time: u0, 
                      preferred-platform: "slack", disruption-sensitivity: u5, last-session: u0 }
                    (get-user-stats tx-sender))))
            (map-set work-sessions
                { session-id: session-id }
                {
                    user: tx-sender,
                    start-time: stacks-block-height,
                    focus-level: u10,
                    disruption-count: u0,
                    is-active: true,
                    target-thoughts: target-thoughts,
                    session-type: session-type
                }
            )
            (map-set user-disruption-stats
                { user: tx-sender }
                (merge current-stats { 
                    total-sessions: (+ (get total-sessions current-stats) u1),
                    last-session: session-id 
                })
            )
            (var-set total-sessions (+ (var-get total-sessions) u1))
            (ok session-id)
        )
    )
)

(define-public (schedule-interruption 
    (session-id uint) 
    (interruption-id uint)
    (target-time uint) 
    (intensity uint) 
    (platform (string-ascii 50))
    )
    (begin
        (asserts! (var-get system-enabled) (err u999))
        (asserts! (<= intensity MAX-INTENSITY) ERR-INVALID-PARAMS)
        (match (get-session-info session-id)
            session-data 
                (begin
                    (asserts! (get is-active session-data) (err u200))
                    (asserts! (< (get disruption-count session-data) MAX-DISRUPTIONS-PER-SESSION) ERR-DISRUPTION-LIMIT-REACHED)
                    (map-set scheduled-interruptions
                        { interruption-id: interruption-id }
                        {
                            session-id: session-id,
                            scheduled-time: target-time,
                            intensity: intensity,
                            status: "scheduled",
                            platform: platform,
                            execution-block: (+ stacks-block-height target-time)
                        }
                    )
                    (ok interruption-id)
                )
            ERR-NOT-FOUND
        )
    )
)

(define-public (measure-focus-level (session-id uint))
    (match (get-session-info session-id)
        session-data
            (let ((time-elapsed (- stacks-block-height (get start-time session-data)))
                  (disruption-impact (* (get disruption-count session-data) u2))
                  (base-focus (get focus-level session-data))
                  (new-focus (if (> base-focus disruption-impact) 
                                (- base-focus disruption-impact) 
                                u1)))
                (map-set work-sessions
                    { session-id: session-id }
                    (merge session-data { focus-level: new-focus })
                )
                (ok new-focus)
            )
        ERR-NOT-FOUND
    )
)

(define-public (trigger-notification 
    (session-id uint) 
    (interruption-id uint)
    (platform (string-ascii 50))
    )
    (begin
        (asserts! (var-get system-enabled) (err u999))
        (match (get-session-info session-id)
            session-data
                (begin
                    (asserts! (get is-active session-data) (err u200))
                    (let ((updated-session (merge session-data { 
                            disruption-count: (+ (get disruption-count session-data) u1) 
                          }))
                          (user-stats (default-to 
                                { total-sessions: u0, successful-disruptions: u0, average-focus-time: u0, 
                                  preferred-platform: "slack", disruption-sensitivity: u5, last-session: u0 }
                                (get-user-stats (get user session-data)))))
                        (map-set work-sessions { session-id: session-id } updated-session)
                        (map-set scheduled-interruptions
                            { interruption-id: interruption-id }
                            {
                                session-id: session-id,
                                scheduled-time: u0,
                                intensity: u0,
                                status: "executed",
                                platform: platform,
                                execution-block: stacks-block-height
                            }
                        )
                        (map-set user-disruption-stats
                            { user: (get user session-data) }
                            (merge user-stats { 
                                successful-disruptions: (+ (get successful-disruptions user-stats) u1) 
                            })
                        )
                        (var-set total-disruptions (+ (var-get total-disruptions) u1))
                        (ok true)
                    )
                )
            ERR-NOT-FOUND
        )
    )
)

(define-public (end-work-session (session-id uint))
    (match (get-session-info session-id)
        session-data
            (begin
                (asserts! (is-eq tx-sender (get user session-data)) ERR-OWNER-ONLY)
                (map-set work-sessions
                    { session-id: session-id }
                    (merge session-data { is-active: false })
                )
                (ok session-id)
            )
        ERR-NOT-FOUND
    )
)

;; Analytics and reporting functions
(define-read-only (get-session-analytics (session-id uint))
    (match (get-session-info session-id)
        session-data
            (let ((duration (- stacks-block-height (get start-time session-data)))
                  (disruption-rate (if (> duration u0) 
                                     (/ (* (get disruption-count session-data) u100) duration) 
                                     u0))
                  (effectiveness (get-disruption-effectiveness session-id)))
                (ok {
                    session-duration: duration,
                    disruption-rate: disruption-rate,
                    effectiveness-score: effectiveness,
                    final-focus-level: (get focus-level session-data)
                })
            )
        ERR-NOT-FOUND
    )
)

(define-read-only (get-platform-performance (platform (string-ascii 50)))
    (ok {
        platform: platform,
        estimated-disruptions: (var-get total-disruptions),
        effectiveness-rating: u85 ;; Hardcoded high effectiveness for demo
    })
)

;; System maintenance
(define-public (perform-maintenance)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set last-maintenance-block stacks-block-height)
        (ok stacks-block-height)
    )
)

;; title: deep-work-disruption-engine
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

