;; [[id:e19c7bb6-c331-4aa8-ba15-9c8cd6156166][DevOS]]
;;
;; Given that the module (clocks package) is in the load path and that it exports the
;; package "clocks", then this module defines an OS that provides a service which
;; starts the clocks executable. The application should expect to communicate with a
;; PostgreSQL database using peer authentication.

(define-module (clocks os))

;; Starting OS to extend
;; ─────────────────────
;;
;; We start with [[ref:7f1cb335-753f-448b-9637-39c130ded682][InitOS]] and extend it.

(use-modules
 (gnu system)
 ((clocks init-os) #:prefix init:))

(define services (operating-system-user-services init:os))
(define packages (operating-system-packages      init:os))

;; Clocks service type
;; ───────────────────
;;
;; [[ref:109bc638-0220-4f10-8b08-82d995bc1752][Application and FHS]]
;; [[ref:b0119404-e5a5-400e-a48c-b1860fc056c0][Service]]
;; [[ref:3e30b0f8-ba72-4fab-a6b0-a89a032fe634][User]]
;; [[ref:88b55fd6-fd20-4b65-a00f-4c6d40c42122][Group]]
;; [[ref:f059b54e-66e9-4090-b3c3-d68f08259458][PostgreSQL]]
;; [[ref:500290c0-845f-4db6-8220-a2182793385f][ServiceType]]

(use-modules
 (gnu packages admin)                   ; shadow
 (gnu packages databases)              ; postgresql
 (gnu packages web)                    ; nginx
 (gnu services)
 (gnu services databases)              ; postgresql-service-type
 (gnu services networking)             ; nftables-service-type
 (gnu services shepherd)
 (gnu services web)                    ; nginx-service-type
 (gnu system accounts)
 ((clocks constant) #:prefix cst:)
 (guix gexp)
 (ice-9 regex))

;; 1. Configuration record.

(define-record-type* <clocks-configuration>
  clocks-configuration make-clocks-configuration
  clocks-configuration?
  (name      clocks-configuration-name      (default "clocks"))
  (port      clocks-configuration-port      (default "4000"))
  (log-file  clocks-configuration-log-file  (default "/var/log/clocks/clocks.log"))
  (env-file  clocks-configuration-env-file  (default "/etc/clocks/env")))

;; 2a. Extension: activation-service-type — create FHS directories.

(define (clocks-fhs-activation config)
  (let* ((name (clocks-configuration-name config))
         (dirs (list (string-append "/etc/"       name)
                     (string-append "/var/lib/"   name)
                     (string-append "/run/"       name)
                     (string-append "/var/log/"   name)
                     (string-append "/var/cache/" name)
                     (string-append "/usr/share/" name)
                     (string-append "/usr/lib/"   name))))
    #~(begin
        (use-modules (guix build utils))
        (for-each
         (lambda (dir) (mkdir-p dir) (chmod dir #o700))
         '#$dirs))))

;; 2b. Extension: account-service-type — declare system user and group.

(define (clocks-accounts config)
  (let* ((name (clocks-configuration-name config))
         (home (string-append "/var/lib/" name)))
    (list
     (user-group
      (name    name)
      (system? #t))
     (user-account
      (name           name)
      (comment        "Application user")
      (group          name)
      (system?        #t)
      (home-directory home)
      (shell          #~(string-append #$shadow "/sbin/nologin"))))))

;; 2c. Extension: postgresql-service-type — peer-auth database.
;;
;; pg_ident maps the OS user "clocks" (and root) to the PostgreSQL role
;; "postgres" via the "appmap" map referenced in pg_hba.

(define (clocks-postgresql config)
  (let* ((name     (clocks-configuration-name config))
         (pg_hba   "\
# TYPE  DATABASE  USER  ADDRESS  METHOD
local   all       all            peer  map=appmap")
         (pg_ident (regexp-substitute/global
                    #f "USER"
                    "\
# MAPNAME  SYSTEM-USERNAME  PG-USERNAME
appmap     USER             postgres
appmap     root             postgres"
                    'pre name 'post)))
    (list
     (service
      postgresql-service-type
      (postgresql-configuration
       (postgresql postgresql)
       (config-file
        (postgresql-config-file
         (hba-file   (plain-file "pg_hba.conf"   pg_hba))
         (ident-file (plain-file "pg_ident.conf" pg_ident)))))))))

;; 2d. Extension: activation-service-type — install dev TLS certificate and key.
;;
;; The certificate is signed by a local CA that the dev browser must trust.
;; Key permissions are intentionally tight (0600).

(define (clocks-certs-activation config)
  (let* ((cert-dir        "/etc/certs")
         (guest-dev-cert  (string-append cert-dir "/dev-cert.pem"))
         (guest-dev-key   (string-append cert-dir "/dev-key.pem"))
         (cert  (local-file (string-append cst:certs-root "dev-cert.pem")))
         (key   (local-file (string-append cst:certs-root "dev-key.pem"))))
    #~(begin
        (use-modules (guix build utils))
        (mkdir-p  #$cert-dir)
        (chmod    #$cert-dir        #o700)
        (copy-file #$cert  #$guest-dev-cert)
        (chmod    #$guest-dev-cert  #o644)
        (copy-file #$key   #$guest-dev-key)
        (chmod    #$guest-dev-key   #o600))))

;; 2e. Extension: nginx-service-type — reverse proxy.
;;
;; :80  → permanent redirect to HTTPS.
;; :443 → TLS termination, forwarded to the app on http://localhost:<port>.
;; A keepalive pool of 32 idle connections avoids per-request TCP handshakes.

(define (clocks-nginx config)
  (let* ((port            (clocks-configuration-port config))
         (cert-dir        "/etc/certs")
         (guest-dev-cert  (string-append cert-dir "/dev-cert.pem"))
         (guest-dev-key   (string-append cert-dir "/dev-key.pem")))
    (list
     (nginx-server-configuration
      (server-name '("localhost" "www.localhost"))
      (listen      '("80"))
      (raw-content '("return 301 https://$host$request_uri;")))
     (nginx-server-configuration
      (server-name         '("localhost" "www.localhost"))
      (listen              '("443 ssl"))
      (ssl-certificate     guest-dev-cert)
      (ssl-certificate-key guest-dev-key)
      (locations
       (list
        (nginx-location-configuration
         (uri "/")
         (body
          (list
           "proxy_set_header X-Real-IP       $remote_addr;"
           "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
           "proxy_set_header X-Forwarded-Proto https;"
           "proxy_set_header Host            $host;"
           (string-append "proxy_pass http://localhost:" port ";")
           "proxy_http_version 1.1;"
           "proxy_set_header Connection \"\";"
           "proxy_connect_timeout 10s;"
           "proxy_read_timeout    60s;"
           "proxy_send_timeout    60s;")))))))))

;; 2f. Extension: nftables-service-type — firewall.
;;
;; Posture: default-deny on input and forward, default-allow on output.
;;   - Inbound traffic is blocked unless explicitly permitted.
;;   - Forward traffic is dropped entirely (this host is not a router).
;;   - Outbound traffic is unrestricted.

(define (clocks-nftables config)
  (nftables-configuration
   (ruleset
    (plain-file "nftables.conf"
                "flush ruleset

table inet filter {

  chain input {
    type filter hook input priority 0; policy drop;

    # Local inter-process traffic (127.0.0.1, ::1).
    iif \"lo\" accept

    # Return traffic for established outbound connections.
    ct state established,related accept

    # ICMP / ICMPv6 — diagnostics and IPv6 neighbour discovery.
    # Rate-limited to prevent amplification attacks.
    ip  protocol icmp   limit rate 10/second burst 5 packets accept
    ip6 nexthdr  icmpv6 limit rate 10/second burst 5 packets accept

    # DHCP replies from the server (bootps → bootpc).
    udp sport bootps udp dport bootpc accept

    # Explicitly exposed TCP ports.
    tcp dport { 22, 80, 443 } accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
  }

  chain output {
    type filter hook output priority 0; policy accept;
  }
}"))))

;; 2g. Extension: shepherd-root-service-type — run the daemon.
;;
;; Reads static env vars inline and merges optional secrets from env-file.
;; Runs database migrations before starting the server process.

(define (clocks-shepherd-service config)
  (list
   (shepherd-service
    (documentation "Application server")
    (provision     '(application))
    (requirement   '(networking postgresql system-log))
    (start
     #~(lambda _
         (let* ((static-env
                 (list
                  (string-append "PATH=" #$coreutils "/bin")
                  (string-append "PORT=" #$(clocks-configuration-port    config))
                  "RELEASE_TMP=/var/lib/clocks/tmp"
                  "HOME=/var/lib/clocks"
                  "LANG=C.UTF-8"
                  "LC_ALL=C.UTF-8"))
                (secret-env
                 (if (file-exists? #$(clocks-configuration-env-file config))
                     (call-with-input-file #$(clocks-configuration-env-file config)
                       (lambda (port)
                         (let loop ((line (read-line port)) (acc '()))
                           (if (eof-object? line)
                               acc
                               (let ((trimmed (string-trim-right line)))
                                 (loop (read-line port)
                                       (if (or (string-null? trimmed)
                                               (string-prefix? "#" trimmed))
                                           acc
                                           (cons trimmed acc))))))))
                     '()))
                (env (append static-env secret-env)))
           (let ((migrate-process
                  ((make-forkexec-constructor
                    (list #$(file-append clocks "/bin/migrate"))
                    #:environment-variables env
                    #:log-file #$(clocks-configuration-log-file config)))))
             (waitpid (process-id migrate-process)))
           ((make-forkexec-constructor
             (list #$(file-append clocks "/bin/clocks") "start")
             #:environment-variables env
             #:log-file #$(clocks-configuration-log-file config))))))
    (stop     #~(make-kill-destructor))
    (respawn? #t))))

;; 3. Service type.

(define clocks-service-type
  (service-type
   (name 'clocks)
   (extensions
    (list
     (service-extension activation-service-type    clocks-fhs-activation)
     (service-extension account-service-type       clocks-accounts)
     (service-extension postgresql-service-type    clocks-postgresql)
     (service-extension activation-service-type    clocks-certs-activation)
     (service-extension nginx-service-type         clocks-nginx)
     (service-extension nftables-service-type      clocks-nftables)
     (service-extension shepherd-root-service-type clocks-shepherd-service)))
   (default-value (clocks-configuration))))

;; 4. Instantiate.

(define clocks-service
  (service clocks-service-type
           (clocks-configuration
            (name     "clocks")
            (port     "4000")
            (log-file "/var/log/clocks/clocks.log")
            (env-file "/etc/clocks/env"))))

(set! services (cons clocks-service services))

;; Application package
;; ───────────────────

;; TODO(1f41): make that a parameter somehow?
(use-modules (clocks package))
(set! packages (cons clocks packages))

;; Operating system
;; ────────────────
;;
;; TODO(4451)
(define-public os
  (operating-system
   (inherit   init:os)
   (host-name "dev-os")
   (packages  packages)
   (services  services)))

os
