;; [[id:e19c7bb6-c331-4aa8-ba15-9c8cd6156166][DevOS]]
;;
;; This module defines dev : OS, as an extension of [[ref:7f1cb335-753f-448b-9637-39c130ded682][init]] : OS.

(define-module (app vm dev os))

(use-modules
 ((gnu services))
 ((gnu services databases))
 ((gnu packages databases))
 ((gnu system))
 ((guix gexp))
 ((gnu services networking))
 ((app vm init os) #:prefix init:)
 ((app vm dev package) #:prefix dev:))

;; We start from services and packages of init : OS
(define services (operating-system-user-services init:os))
(define packages (operating-system-packages init:os))

;; A PostgreSQL instance should be running and associated package for local
;; diagnostics. TODO(e57f): for some reason, we need to run initdb ourself if
;; necessary.
(define postgresql-initdb-service
  (simple-service
   'postgresql-initdb
   activation-service-type
   #~(begin
       (use-modules (guix build utils))
       (let ((data-dir "/var/lib/postgresql/data"))
         (unless (file-exists? (string-append data-dir "/PG_VERSION"))
           (mkdir-p data-dir)
           (chown data-dir
                  (passwd:uid (getpwnam "postgres"))
                  (passwd:gid (getpwnam "postgres")))
           (invoke "su" "-s" "/bin/sh" "postgres"
                   "-c" (string-append "initdb -D " data-dir)))))))
(set! services (cons postgresql-initdb-service services))
(define postgresql-service
  (service
   postgresql-service-type
   (postgresql-configuration
    (postgresql postgresql))))
(set! services (cons postgresql-service services))
(set! packages (cons postgresql packages))

;; ─────────────────────────────────────────────────────────────────────────────
;; FIREWALL CONFIGURATION
;;
;; We use nftables, the modern Linux packet-filtering framework that supersedes
;; iptables. Guix exposes it through `nftables-service-type`, which takes a
;; configuration record whose `ruleset` field is a file-like object containing
;; the raw nftables rule syntax.
;;
;; The overall posture is "default deny on input and forward, default allow on
;; output". This means:
;;   - Traffic arriving at this machine is blocked unless explicitly permitted.
;;   - Traffic being routed *through* this machine is blocked (we're not a
;;     router, so nothing should arrive here for forwarding anyway).
;;   - Traffic *originating from* this machine is unrestricted.
;; ─────────────────────────────────────────────────────────────────────────────
(define nftables-service
  (service
   nftables-service-type
   (nftables-configuration
    (ruleset (plain-file "nftables.conf"

      ;; We start from an empty ruleset.
      "flush ruleset

      # `inet` tables match both IPv4 and IPv6, so we only need one table
      # instead of separate `ip` and `ip6` tables.
      table inet filter {

        # ── INPUT CHAIN ─────────────────────────────────────────────────────
        # Processes all packets whose destination is this machine itself since
        # it is not a router (as opposed to packets that merely transit
        # through it).
        chain input {
          # any packet that doesn't match an explicit `accept` rule below is
          # silently discarded.
          type filter hook input priority 0; policy drop;

          # The loopback interface (lo) carries local inter-process traffic
          # (127.0.0.1, ::1). Blocking it would break many daemons that talk
          # to each other over localhost.
          iif \"lo\" accept

          # Once a connection has been initiated and accepted, allow the
          # return traffic back in automatically. Without this rule every
          # outbound request (apt, curl, SSH *to* another host, etc.) would
          # get no response, because the reply packets would be dropped.
          # `related` covers ancillary flows such as ICMP error messages that
          # belong to an existing connection.
          ct state established,related accept

          # Allows ping (useful for diagnosing connectivity) and, crucially
          # for IPv6, Neighbour Discovery Protocol messages (router
          # advertisements, neighbour solicitations) which the OS needs to
          # resolve link-layer addresses. Blocking ICMPv6 breaks IPv6
          # entirely on most networks.
          # Rate limiting to 10 packets/second with a burst allowance of 5
          # prevents this machine from being used as an ICMP amplification
          # reflector while still allowing normal diagnostic use. Packets
          # beyond the limit are dropped by the default input policy.
          ip protocol icmp limit rate 10/second burst 5 packets accept
          ip6 nexthdr icmpv6 limit rate 10/second burst 5 packets accept

          # When the VM requests an IP address, it broadcasts a DISCOVER
          # packet from UDP port 68 (bootpc) to port 67 (bootps). The DHCP
          # server's OFFER reply is addressed back to port 68. This rule lets
          # that reply packet in.
          udp sport bootps udp dport bootpc accept

          # The only two TCP ports this VM intentionally exposes:
          #   22  — SSH, for remote administration
          #   80  — HTTP, for the web service
          # All other TCP/UDP ports remain blocked by the default drop policy.
          tcp dport { 22, 80, 443 } accept
        }

        # ── FORWARD CHAIN ───────────────────────────────────────────────────
        # Handles packets that arrive on one interface and are destined for
        # another (i.e. routing). This VM is not a router, so we drop
        # everything here as a hard guarantee — even if IP forwarding were
        # accidentally enabled in the kernel, no traffic could leak through.
        chain forward {
          type filter hook forward priority 0; policy drop;
        }

        # ── OUTPUT CHAIN ────────────────────────────────────────────────────
        # Governs packets that originate from processes running on this
        # machine. `policy accept` allows unrestricted outbound connections —
        # package downloads, DNS lookups, outgoing SSH, etc.
        chain output {
          type filter hook output priority 0; policy accept;
        }
      }")))))
(set! services (cons nftables-service services))

;; TODO(7d53): nginx
;; TODO(f529): add dev:package
;; TODO(f529): add dev:service

;; Finally, the operating is defined as an extension of init : OS
(define-public os
  (operating-system
   (inherit init:os)
   (host-name "dev-os")
   (packages packages)
   (services services)))

;; So that `guix system image -t qcow2 /…/os.scm' works
os
