;; [[id:ba507950-c82c-45cc-bc27-a2af31d74e65][os-14]]
;;
;; update [[id:0b4ce8e5-bc2d-4907-a01e-38d5e789c5e4][os-13]] so that it can be deployed to Hetzner cloud

(define-module (clocks os os-14))

(use-modules
 ((clocks channels) #:prefix ch:)
 ((clocks constant) #:prefix cst:)
 (gnu bootloader grub)
 (gnu bootloader)
 (gnu home services)
 (gnu home)
 (gnu packages admin)
 (gnu packages base)
 (gnu packages bash)
 (gnu packages tls)
 (gnu packages databases)
 (gnu packages emacs)
 (gnu packages emacs-xyz)
 (gnu packages linux)
 (gnu packages ncdu)
 (gnu packages rust-apps)
 (gnu packages web)
 (gnu services admin)
 (gnu services base)
 (gnu services certbot)
 (gnu services databases)
 (gnu services guix)
 (gnu services networking)
 (gnu services shepherd)
 (gnu services ssh)
 (gnu services web)
 (gnu services)
 (gnu system file-systems)
 (gnu system keyboard)
 (gnu system locale)
 (gnu system shadow)
 (gnu system)
 (guix build-system copy)
 (guix gexp)
 (guix packages)
 (guix records)
 (ice-9 match)
 (ice-9 regex))

;; ApplicationConf
;; ─────────────

(define-record-type* <application-conf>
  application-conf make-application-conf
  application-conf?
  (version application-conf-version (default "0.0.0"))
  (mode application-conf-mode (default "dev"))
  (dist application-conf-dist (default "/dev/null"))
  (name application-conf-name (default "application"))
  (port application-conf-port (default "4000"))
  (host-name application-conf-host-name (default "localhost"))
  (ssh-root-pub-key-path application-conf-ssh-root-pub-key-path (default "/dev/null"))
  (email application-conf-email (default "admin@localhost")))

(define (application-conf-check value)
  "value:Any → ∅

Raise an error if value is not a ApplicationConf"

  (unless (application-conf? value)
    (error "value is not a ApplicationConf: ~S" value)))

(define (application-conf-dev? conf)
  "ApplicationConf → Boolean

Return #t iff mode is dev"

  (application-conf-check conf)
  (string=? (application-conf-mode conf) "dev"))

(define (application-conf-prod? conf)
  "ApplicationConf → Boolean

Return #t iff mode is prod"

  (application-conf-check conf)
  (string=? (application-conf-mode conf) "prod"))

(define (application-conf-home conf)
  "ApplicationConf → String

Return the path of the home directory in the VM of the user that operates the application"

  (application-conf-check conf)
  (string-append "/var/lib/" (application-conf-name conf)))

(define (application-conf-log conf)
  "ApplicationConf → String

Return the path of the log directory in the VM of the user that operates the application"

  (application-conf-check conf)
  (string-append "/var/log/" (application-conf-name conf)))

(define (application-conf-etc conf)
  "ApplicationConf → String

Return the path of the etc directory in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append "/etc/" (application-conf-name conf)))

(define (application-conf-secret conf)
  "ApplicationConf → String

Return the path of the secrets directory in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append (application-conf-etc conf) "/secret"))

(define (application-conf-run conf)
  "ApplicationConf → String

Return the path of the run directory in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append "/run/" (application-conf-name conf)))

(define (application-conf-pid-file conf)
  "ApplicationConf → String

Return the path of the PID file in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append (application-conf-run conf) "/" (application-conf-name conf) ".pid"))

(define (application-conf-log-file conf)
  "ApplicationConf → String

Return the path of the log file in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append (application-conf-log conf) "/" (application-conf-name conf) ".log"))

(define (application-conf-certs conf)
  "ApplicationConf → String

Return the path of the certificates directory in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append (application-conf-etc conf) "/certs"))

(define (application-conf-cert conf)
  "ApplicationConf → String

Return the path of the certificate file in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append (application-conf-certs conf) "/cert.pem"))

(define (application-conf-cert-key conf)
  "ApplicationConf → String

Return the path of the certificate key file in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append (application-conf-certs conf) "/cert.key"))

(define (application-conf-server conf)
  "ApplicationConf → GExp

Return the gexp that results into the path to the server"

  (application-conf-check conf)
  (file-append (application-conf-package conf) "/bin/server"))

(define (application-conf-migrate conf)
  "ApplicationConf → GExp

Return the gexp that results into the path to the migration executable"

  (application-conf-check conf)
  (file-append (application-conf-package conf) "/bin/migrate"))

(define (application-conf-ssh-root-pub-key conf)
  "ApplicationConf → local-file

Return the local-file object referring to the public SSH key used to identify the root user on the VM"

  (application-conf-check conf)
  (local-file (application-conf-ssh-root-pub-key-path conf)))

(define (application-conf-locale conf)
  "ApplicationConf → String

Return the name of the locale used"

  (application-conf-check conf)
  "C.UTF-8")

;; Application package
;; ───────────────────

(define (application-conf-package config)
  "ApplicationConf → Package"

  (application-conf-check config)
  (let ((name (application-conf-name config))
        (version (application-conf-version config))
        (dist (application-conf-dist config)))
    (package
     (name name)
     (version version)
     (source (local-file dist #:recursive? #t))
     (build-system copy-build-system)
     (arguments (list #:install-plan ''(("dist/" "/"))
                      #:strip-binaries? #f
                      #:validate-runpath? #f))
     (synopsis "package for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]]")
     (description "package for a [[ref:53ed1487-e1d0-4cdd-a4cc-c7b810bf9b17][Distribution]]")
     (license #f)
     (home-page #f))))

;; Users
;; ─────
;;
;; root user owns the system.
;; application user owns the subset of the system necessary to operate the application.
;;
;; References:
;;   [[ref:1fd5d002-cfc2-4556-8859-f79bd94d08e3][Linux and users]]

(define (application-groups-and-accounts conf)
  "ApplicationConf → List(Group | Account)"

  (application-conf-check conf)
  (let* ((name (application-conf-name conf))
         (home (application-conf-home conf)))
    (list
     (user-group
      (name name)
      (system? #t))
     (user-account
      (name name)
      (comment "Application user")
      (group name)
      (system? #t)
      (home-directory home)

      ;; [[ref:adc94f2b-b7de-4784-8e88-a992b390683e][nologin]]
      (shell #~(string-append #$shadow "/sbin/nologin"))))))

;; File system
;; ───────────
;;
;; A set of necessary files for the application to execute is owned by application.
;;
;; References:
;;   [[ref:109bc638-0220-4f10-8b08-82d995bc1752][FHS]]
;;   [[ref:c12b81b0-eeeb-46de-9c1e-26d5113cbfdd][ShepherdService]]

(define (application-certs conf)
  "ApplicationConf → G-expression

Return a G-expression that creates the certificates directory under /etc/<name>/certs
and copies the development TLS certificate and private key with correct permissions"

  (application-conf-check conf)
  (let* ((certs (application-conf-certs conf))
         (host-cert (local-file (string-append cst:certs-root "/dev-cert.pem")))
         (cert (application-conf-cert conf))
         (host-cert-key (local-file (string-append cst:certs-root "/dev-key.pem")))
         (cert-key (application-conf-cert-key conf)))
    #~(begin
        (use-modules (guix build utils))
        (mkdir-p #$certs)
        (chmod #$certs #o700)
        (copy-file #$host-cert #$cert)
        (chmod #$cert #o644)
        (copy-file #$host-cert-key #$cert-key)
        (chmod #$cert-key #o600))))

(define (application-file-system conf)
  "ApplicationConf → ShepherdService"

  (application-conf-check conf)

  (let* ((name (application-conf-name conf))
         (home (application-conf-home conf))
         (etc (application-conf-etc conf))
         (secret (application-conf-secret conf))
         (run (application-conf-run conf))
         (log (application-conf-log conf))
         (dev-mode (application-conf-dev? conf))

         ;; Directories the application user should own and write to
         (app-dirs
          (list home
                run
                log
                (string-append "/var/cache/" name)
                (string-append "/usr/share/" name)
                (string-append "/usr/lib/"   name)))

         ;; Directories that should be root-owned
         (root-dirs
          (list etc secret)))

    (shepherd-service
     (provision '(application-file-system))
     (requirement '(user-processes))
     (one-shot? #t)
     (documentation "Create application directories and set ownership")
     (modules '((guix build utils)
                (rnrs io ports)))
     (start
      #~(lambda _
          ;; Create all directories as root
          (for-each mkdir-p (append '#$app-dirs '#$root-dirs))

          ;; Application-owned directories
          (let* ((pw  (getpwnam #$name))
                 (uid (passwd:uid pw))
                 (gid (passwd:gid pw)))
            (for-each
             (lambda (dir)
               (chown dir uid gid)
               (chmod dir #o700))
             '#$app-dirs))

          ;; Root-owned directories
          (for-each (lambda (dir) (chmod dir #o755)) '#$root-dirs)

          (define (bytevector->hex bv)
            (apply string-append
                   (map (lambda (b)
                          (let ((s (number->string b 16)))
                            (if (= (string-length s) 1)
                                (string-append "0" s)
                                s)))
                        (bytevector->u8-list bv))))

          ;; Only write if file does not exist
          (define (ensure-secret filename value-or-thunk)
            (let ((path (string-append #$secret "/" filename)))
              (unless (file-exists? path)
                (let ((value (if (procedure? value-or-thunk)
                                 (value-or-thunk)
                                 value-or-thunk)))
                  (call-with-output-file path
                    (lambda (port) (display value port)))
                  (chmod path #o600)))))

          ;; If dev-mode, use fixed development secrets
          (if #$dev-mode
              (begin
                (ensure-secret "SECRET_KEY_BASE"
                               "Z8DeDEXcl3tVcyN6HfEUu60yuMUaKKX29ViWUSF0/PLgPM8DkenrHlJRBahDxUJc")
                (ensure-secret "XAI_API_KEY"
                               "sk-000000"))
              (begin
                (ensure-secret "SECRET_KEY_BASE"
                               (lambda ()
                                 (bytevector->hex
                                  (get-bytevector-n (open-input-file "/dev/urandom" #:binary #t) 32))))
                (ensure-secret "XAI_API_KEY"
                               "sk-000000")))

          #$(application-certs conf)

          #t))
     (stop #~(make-kill-destructor)))))

;; Application environment
;; ───────────────────────

(define (application-conf-env conf)
  "ApplicationConf → GExpression
Produces a gexp that, at service start time, returns the full env list."
  (let* ((port   (application-conf-port conf))
         (host   (application-conf-host-name conf))
         (locale (application-conf-locale conf))
         (pkg    (application-conf-package conf))
         (secret (application-conf-secret conf)))
    #~(let* ((static-env
              (list
               "PHX_SERVER=true"
               (string-append "PHX_HOST=" #$host)
               (string-append "PORT="     #$port)
               (string-append "LC_ALL="   #$locale)
               (string-append "PATH="
                              #$(file-append bash "/bin")       ":"
                              #$(file-append postgresql "/bin") ":"
                              #$(file-append pkg "/bin")        ":"
                              #$(file-append coreutils "/bin")  ":"
                              #$(file-append sed "/bin")        ":"
                              #$(file-append grep "/bin"))))
             (secret-env
              (map (lambda (filename)
                     (let* ((path  (string-append #$secret "/" filename))
                            (value (string-trim-right
                                    (call-with-input-file path get-string-all))))
                       (string-append filename "=" value)))
                   (scandir #$secret (lambda (f) (not (member f '("." ".."))))))))
        (append static-env secret-env))))

;; Application init
;; ────────────────
;;
;; Initialize the DB if needed.
;; Perform migration of the DB.

(define (application-init conf)
  "ApplicationConf → ShepherdService"
  (application-conf-check conf)
  (let* ((name    (application-conf-name conf))
         (migrate (application-conf-migrate conf)))
    (shepherd-service
     (provision '(application-init))
     (requirement '(application-file-system postgres))
     (one-shot? #t)
     (documentation "Initialize the application database")
     (modules '((shepherd service)
                (guix build utils)
                (ice-9 ftw)
                (ice-9 textual-ports)))
     (start
      #~(lambda _
          (let* ((env #$(application-conf-env conf)))
            ((make-forkexec-constructor
              (list #$(file-append bash "/bin/bash") "-c"
                    (string-append "createdb -U postgres " #$name
                                   " || true && " #$migrate))
              #:environment-variables env
              #:user  #$name
              #:group #$name)))))
     (stop #~(make-kill-destructor)))))

;; Certbot bootstrap (prod only)
;; ─────────────────────────────
;;
;; On first boot in prod, /etc/letsencrypt/live/<host>/ does not exist yet.
;; nginx cannot start with a missing certificate file, so we need a one-shot
;; Shepherd service that:
;;
;;   1. Runs before nginx (nginx depends on it via requirement).
;;   2. Uses certbot --standalone on port 80 to issue the initial certificate.
;;   3. Is idempotent: skips the certbot call if the certificate already exists
;;      (e.g. after a reboot once the cert has been issued).
;;
;; Subsequent renewals are handled automatically by the timer installed by
;; certbot-service-type; the deploy-hook reloads nginx via herd.

(define (application-certbot-init conf)
  "ApplicationConf → ShepherdService | #f

Return a one-shot Shepherd service that issues the initial Let's Encrypt
certificate when in prod mode, or #f in dev mode."

  (application-conf-check conf)
  (cond
   ((application-conf-dev? conf) #f)
   ((application-conf-prod? conf)
    (let* ((host-name (application-conf-host-name conf))
           (email     (application-conf-email conf)))
      (shepherd-service
       (provision '(application-certbot-init))
       ;; networking must be up; file-system creates /etc/<name> dirs.
       ;; Must complete before nginx starts (nginx lists this in requirement).
       (requirement '(networking application-file-system))
       (one-shot? #t)
       (documentation "Issue the initial Let's Encrypt TLS certificate via certbot --standalone")
       (modules '((guix build utils)))
       (start
        #~(lambda _
            (let ((cert (string-append "/etc/letsencrypt/live/" #$host-name "/fullchain.pem")))
              (if (file-exists? cert)
                  (begin
                    (format #t "certbot: certificate already exists, skipping initial issuance~%")
                    #t)
                  ;; --standalone spins up a temporary HTTP server on port 80
                  ;; for the ACME HTTP-01 challenge.  nginx is not yet running
                  ;; at this point (it depends on this service), so port 80 is free.
                  (zero? (system*
                          #$(file-append certbot "/bin/certbot")
                          "certonly"
                          "--standalone"
                          "--non-interactive"
                          "--agree-tos"
                          "--email"  #$email
                          "-d"       #$host-name
                          "-d"       (string-append "www." #$host-name)))))))
       (stop #~(make-kill-destructor)))))
   (#t (throw 'unexpected-mode))))

;; Application start
;; ─────────────────

(define (application-start conf)
  "ApplicationConf → ShepherdService

Return the Shepherd service that runs the application server."
  (application-conf-check conf)
  (let* ((name     (application-conf-name conf))
         (log-file (application-conf-log-file conf))
         (server   (application-conf-server conf))
         ;; In prod, wait for certbot-init before starting (nginx depends on
         ;; certbot-init too, but being explicit here makes the graph clear).
         (extra-reqs (if (application-conf-prod? conf)
                         '(application-certbot-init)
                         '())))
    (shepherd-service
     (provision '(application-start))
     (requirement `(user-processes
                    networking
                    application-init
                    syslogd
                    nginx
                    postgres
                    ,@extra-reqs))
     (documentation "Application server")
     (modules '((shepherd service)
                (guix build utils)
                (ice-9 ftw)
                (ice-9 textual-ports)))
     (start
      #~(lambda _
          (let* ((env #$(application-conf-env conf)))
            ((make-forkexec-constructor
              (list #$server)
              #:environment-variables env
              #:user     #$name
              #:group    #$name
              #:log-file #$log-file)))))
     (stop #~(make-kill-destructor)))))

;; Database
;; ────────
;;
;; References:
;;    [[ref:f059b54e-66e9-4090-b3c3-d68f08259458][PostgreSQL]]

(define (application-database conf)
  "ApplicationConf → Service"

  (application-conf-check conf)
  (let* ((name   (application-conf-name conf))
         (locale (application-conf-locale conf))
         (pg_hba   "\
# TYPE  DATABASE  USER  ADDRESS  METHOD
local   all       all            peer  map=appmap")
         (pg_ident (format #f "\
# MAPNAME  SYSTEM-USERNAME PG-USERNAME
appmap     ~a              postgres
appmap     root            postgres" name)))
    (service
     postgresql-service-type
     (postgresql-configuration
      (postgresql postgresql)
      (locale locale)
      (config-file
       (postgresql-config-file
        (hba-file   (plain-file "pg_hba.conf"   pg_hba))
        (ident-file (plain-file "pg_ident.conf" pg_ident))))))))

;; Reverse proxy
;; ─────────────

(define (application-conf-ssl-certificate conf)
  "ApplicationConf → String

Return the path to the SSL certificate file:
- In dev mode: the self-signed development certificate at /etc/<name>/certs/cert.pem
- In prod mode: the Let's Encrypt fullchain.pem managed by certbot at
  /etc/letsencrypt/live/<host-name>/fullchain.pem"

  (application-conf-check conf)
  (cond
   ((application-conf-dev? conf)
    (application-conf-cert conf))
   ((application-conf-prod? conf)
    (string-append "/etc/letsencrypt/live/" (application-conf-host-name conf) "/fullchain.pem"))
   (#t
    (throw 'unexpected-mode))))

(define (application-conf-ssl-certificate-key conf)
  "ApplicationConf → String

Return the path to the SSL certificate private key file:
- In dev mode: the development key at /etc/<name>/certs/cert.key
- In prod mode: the Let's Encrypt privkey.pem managed by certbot at
  /etc/letsencrypt/live/<host-name>/privkey.pem"

  (application-conf-check conf)
  (cond
   ((application-conf-dev? conf)
    (application-conf-cert-key conf))
   ((application-conf-prod? conf)
    (string-append "/etc/letsencrypt/live/" (application-conf-host-name conf) "/privkey.pem"))
   (#t
    (throw 'unexpected-mode))))

(define (application-reverse-proxy conf)
  "ApplicationConf → Service

Return an nginx service configured as a reverse proxy for the application:
HTTP requests are redirected to HTTPS and all traffic is forwarded to the
internal application port using the configured TLS certificate and key
(development self-signed cert in dev mode, or Let's Encrypt cert managed by
certbot in prod mode).

In prod, nginx lists application-certbot-init in its requirement so it only
starts after the initial certificate has been issued."

  (application-conf-check conf)
  (let* ((port          (application-conf-port conf))
         (host-name     (application-conf-host-name conf))
         (host-name-list (list host-name (string-append "www." host-name))))
    (service
     nginx-service-type
     (nginx-configuration
      ;; In prod, delay nginx startup until the initial certificate exists.
      ;; certbot-init provisions it; after that nginx can load the cert file.
      (shepherd-requirement
       (if (application-conf-prod? conf)
           '(application-certbot-init)
           '()))
      (server-blocks
       (list
        (nginx-server-configuration
         (server-name host-name-list)
         (listen '("80"))
         (raw-content '("return 301 https://$host$request_uri;")))

        (nginx-server-configuration
         (server-name host-name-list)
         (listen '("443 ssl"))
         (ssl-certificate     (application-conf-ssl-certificate conf))
         (ssl-certificate-key (application-conf-ssl-certificate-key conf))
         (locations
          (list
           (nginx-location-configuration
            (uri "/")
            (body
             (list
              "proxy_set_header X-Real-IP $remote_addr;"
              "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
              "proxy_set_header X-Forwarded-Proto https;"
              "proxy_set_header Host $host;"
              (string-append "proxy_pass http://localhost:" port ";")
              "proxy_http_version 1.1;"
              "proxy_set_header Connection \"\";"
              "proxy_connect_timeout 10s;"
              "proxy_read_timeout 60s;"
              "proxy_send_timeout 60s;"))))))))))))

;; Firewall
;; ────────

(define (application-firewall conf)
  "ApplicationConf → Service

Return an nftables firewall service with a strict input policy that allows only
SSH (port 22), HTTP/HTTPS (ports 80/443), loopback, established/related connections,
ICMP, and DHCP client replies while dropping everything else"

  (application-conf-check conf)
  (service
   nftables-service-type
   (nftables-configuration
    (ruleset
     (plain-file "nftables.conf"
                 "# We start from an empty ruleset.
      flush ruleset

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

          # The only TCP ports this VM intentionally exposes:
          #   22  — SSH, for remote administration
          #   80  — HTTP, for the web service
          #   443 — HTTPS
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

;; SSH daemon
;; ──────────

(define (application-sshd conf)
  "ApplicationConf → Service

Return an OpenSSH service configured to allow root login only via the provided
public key (password authentication is disabled)"

  (application-conf-check conf)
  (let ((pub-key (application-conf-ssh-root-pub-key conf)))
    (service
     openssh-service-type
     (openssh-configuration
      (permit-root-login 'prohibit-password)
      (password-authentication? #f)
      (generate-host-keys? #t)
      (authorized-keys
       `(("root" ,pub-key)))))))

;; Certbot service (prod only)
;; ───────────────────────────
;;
;; certbot-service-type installs a renewal timer.  The deploy-hook reloads
;; nginx via herd so renewed certificates are picked up without downtime.
;; Initial certificate issuance is handled by application-certbot-init (a
;; one-shot Shepherd service) rather than here, so that nginx can declare a
;; proper Shepherd dependency on it.

(define (application-certbot conf)
  "ApplicationConf → Service | #f

Return a certbot service configured for the application's host-name when in
prod mode, or #f in dev mode (where self-signed certs are used instead)."

  (application-conf-check conf)
  (cond
   ((application-conf-dev? conf) #f)
   ((application-conf-prod? conf)
    (let* ((host-name (application-conf-host-name conf))
           (email     (application-conf-email conf))
           (domains   (list host-name (string-append "www." host-name))))
      (service
       certbot-service-type
       (certbot-configuration
        (email email)
        (certificates
         (list
          (certificate-configuration
           (domains domains)
           (deploy-hook
            (program-file
             "certbot-deploy-hook"
             ;; Reload nginx via Shepherd so it picks up the renewed cert.
             ;; Using `herd` (not `nginx -s reload`) keeps Shepherd's process
             ;; model consistent.
             #~(zero? (system*
                       #$(file-append shepherd "/bin/herd")
                       "reload" "nginx")))))))))))
   (#t (throw 'unexpected-mode))))

;; Application shepherd services
;; ─────────────────────────────
;;
;; Startup order:
;;
;;   application-file-system          (creates dirs, dev secrets/certs)
;;     └─ application-certbot-init    (prod only: issues initial LE cert)
;;         └─ nginx                   (can now load the cert file)
;;     └─ postgres
;;         └─ application-init        (createdb + migrate)
;;             └─ application-start   (runs the server)


(define (application-shepherd-services conf)
  "ApplicationConf → List(ShepherdService)"

  (application-conf-check conf)
  ;; filter out #f entries produced by prod-only services running in dev mode
  (filter identity
          (list (application-file-system conf)
                (application-certbot-init conf)
                (application-init conf)
                (application-start conf))))

;; Application service type
;; ────────────────────────

(define application-service-type
  (service-type
   (name 'application)
   (description "application")
   (extensions
    (list
     (service-extension account-service-type application-groups-and-accounts)
     (service-extension shepherd-root-service-type application-shepherd-services)))
   (default-value (application-conf))))

;; Home configurations
;; ───────────────────
;;
;; Add tools to root so that it can operate administrative tasks. Same idea for other
;; users.

(define (application-root-home config)
  "ApplicationConf → Service

Return a `guix-home-service-type` service that configures a comfortable
environment for the root user.  It includes Emacs together with Guile/Scheme
development tools as well as a curated selection of CLI utilities useful for
system administration, networking diagnostics, firewall management, system-log
analysis, debugging, monitoring, file management, and general server
maintenance."

  (application-conf-check config)

  (service
   guix-home-service-type
   (list
    (list "root"
          (home-environment
           (packages
            (list
             emacs-geiser
             emacs-geiser-guile
             emacs-guix
             emacs-minimal
             emacs-paredit
             (default-guile)
             postgresql
             fd
             ripgrep
             ncdu
             nftables
             strace
             iproute
             (application-conf-package config))))))))

;; Configuration
;; ─────────────

(define configuration
  (application-conf
   (name "application")
   (mode "prod")
   (version "0.1.0")
   (host-name "todo.test.phfrohring.com")
   (email "contact@phfrohring.com")
   (dist cst:backend-dist)
   (ssh-root-pub-key-path cst:dev-public-key-path)))

;; Operating system
;; ────────────────

(define-public os-14
  (operating-system
   (host-name (application-conf-name configuration))
   (timezone "Etc/UTC")
   (locale (application-conf-locale configuration))
   (locale-libcs (list glibc))
   (locale-definitions
    (list
     (locale-definition (source "C") (name (application-conf-locale configuration)))))
   (keyboard-layout (keyboard-layout "fr"))

   (bootloader
    (bootloader-configuration
     (bootloader grub-bootloader)
     (targets '("/dev/sda"))
     (keyboard-layout keyboard-layout)))

   (file-systems
    (cons (file-system
           (mount-point "/")
           (device "/dev/sda1")
           (type "ext4"))
          %base-file-systems))

   (services
    ;; filter identity removes #f produced by prod-only services in dev mode
    ;; (e.g. application-certbot returns #f when mode is "dev")
    (filter identity
            (cons*
             (service dhcpcd-service-type)
             (application-sshd configuration)
             (application-firewall configuration)
             (application-reverse-proxy configuration)
             (application-database configuration)
             (service application-service-type configuration)
             (application-root-home configuration)
             (application-certbot configuration)
             (modify-services %base-services
                              (guix-service-type
                               config =>
                               (guix-configuration
                                (inherit config)
                                (channels ch:channels)
                                (authorized-keys
                                 (cons (local-file "/etc/guix/signing-key.pub")
                                       (guix-configuration-authorized-keys config)))))))))))

;; Result
;; ──────

os-14
