;; [[id:a3c28cb6-6f1f-4fcb-aea2-15561d9c96b1][9.scm]]
;;
;; Add application to [[ref:631acfd4-d897-4304-a053-04f05959fe2c][8.scm]]
;; $(guix system vm scheme/os-experiment/9.scm) \
;;   -m 2G \
;;   -nic user,model=virtio-net-pci,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443,hostfwd=tcp::2222-:22

(use-modules
 ((clocks constant) #:prefix cst:)
 (gnu bootloader grub)
 (gnu bootloader)
 (gnu home services)
 (gnu home)
 (gnu packages admin)
 (gnu packages base)
 (gnu packages databases)
 (gnu packages emacs)
 (gnu packages emacs-xyz)
 (gnu packages linux)
 (gnu packages ncdu)
 (gnu packages rust-apps)
 (gnu services base)
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

;; Application parameters
;; ──────────────────────
;;
;; Represents what can be configured about the application.
;;
;;
;; Lang :≡ "fr" | "en" | String
;;
;; Name :≡ String that represents the name of the application
;;
;; Version :≡ String that represents the version of the application, e.g. 0.1.0
;;
;; Dist :≡ Path to a [[ref:0b6d8a58-28c7-4d29-891d-b8f879659688][PhoenixDistribution]]
;;
;; Port :≡ String that represents the port of the inner web server to which the
;;         reverse proxy routes requests.
;;
;; HostName :≡ String that represents the domain from which HTTP request are supposed
;;             to come from, e.g. "localhost" or "mywebsite"
;;
;; RootPubKey :≡ The path on this filesystem to the public key used to identify the
;;               root user on the VM, e.g. /path/to/ed25519.pub
;;
;; ApplicationConf#mk : Lang Name Port HostName RootPubKey → ApplicationConf

(define-record-type* <application-conf>
  application-conf make-application-conf
  application-conf?
  (lang application-conf-lang (default "en"))
  (version application-conf-version (default "0.0.0"))
  (dist application-conf-dist (default "/dev/null"))
  (name application-conf-name (default "application"))
  (port application-conf-port (default "4000"))
  (host-name application-conf-host-name (default "localhost"))
  (ssh-root-pub-key-path application-conf-ssh-root-pub-key-path (default "/dev/null")))

(define (application-conf-check value)
  "value:Any → ∅

Raise an error if value is not a ApplicationConf"

  (unless (application-conf? value)
    (error "value is not a ApplicationConf: ~S" value)))

(define (application-conf-home conf)
  "ApplicationConf → String

Return the path of the home directory in the VM of the user that operates the application"

  (application-conf-check conf)
  (string-append "/var/lib/" (application-conf-name conf)))

(define (application-conf-etc conf)
  "ApplicationConf → String

Return the path of the etc directory in the VM of the application according to FHS"

  (application-conf-check conf)
  (string-append "/etc/" (application-conf-name conf)))

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

(define (application-master config)
  "ApplicationConf → list

Return a list containing a one-shot Shepherd service that prints a greeting message in the configured language"

  (application-conf-check config)
  (let* ((lang (application-conf-lang config))
         (msg (match lang
                ("fr" "Bonjour, monde!")
                ("en" "Application, world!")
                (lang (format #f "Unexpected lang: ~S" lang)))))
    (list
     (shepherd-service
      (provision '(application))
      (documentation "Print a greeting.")
      (start  #~(lambda _
                  (display #$msg)
                  (newline)
                  #t))
      (stop   #~(lambda _ #t))
      (one-shot? #t)))))

;; [[ref:109bc638-0220-4f10-8b08-82d995bc1752][Application and FHS]]
;; ────────────────────

(define (application-fhs config)
  (application-conf-check config)
  (let* ((name (application-conf-name config))
         (home (application-conf-home config))
         (etc (application-conf-etc config))
         (dirs (list etc
                     home
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

;; [[ref:1fd5d002-cfc2-4556-8859-f79bd94d08e3][Linux and users]]
;; ────────────────

(define (application-accounts config)
  (application-conf-check config)
  (let* ((name (application-conf-name config))
         (home (application-conf-home config)))
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

;; [[ref:f059b54e-66e9-4090-b3c3-d68f08259458][PostgreSQL]]
;; ───────────

(define (application-database config)
  (application-conf-check config)
  (let* ((name (application-conf-name config))
         (locale (application-conf-locale config))
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

;; Certificates
;; ────────────

;; TODO(2e7d): there must be a distinction between dev and prod mode since in
;; production mode certificates are obtained from cert bots instead of locally signed
;; ones reserved for development.
(define (application-certs config)
  "ApplicationConf → G-expression

Return a G-expression that creates the certificates directory under /etc/<name>/certs
and copies the development TLS certificate and private key with correct permissions"

  (application-conf-check config)
  (let* ((certs (application-conf-certs config))
         (host-cert (local-file (string-append cst:certs-root "/dev-cert.pem")))
         (cert (application-conf-cert config))
         (host-cert-key (local-file (string-append cst:certs-root "/dev-key.pem")))
         (cert-key (application-conf-cert-key config)))
    #~(begin
        (use-modules (guix build utils))
        (mkdir-p #$certs)
        (chmod #$certs #o700)
        (copy-file #$host-cert #$cert)
        (chmod #$cert #o644)
        (copy-file #$host-cert-key #$cert-key)
        (chmod #$cert-key #o600))))

;; Activation
;; ──────────

(define (application-activation config)
  "ApplicationConf → G-expression

Return a G-expression that performs the activation steps for the application:
setting up the FHS directories and installing the certificates"

  (application-conf-check config)
  (let ((fhs (application-fhs   config))
        (certs (application-certs config)))
    #~(begin #$fhs #$certs)))

;; Reverse proxy
;; ─────────────

(define (application-reverse-proxy config)
  "ApplicationConf → Service

Return an nginx service configured as a reverse proxy for the application:
HTTP requests are redirected to HTTPS and all traffic is forwarded to the
internal application port using the configured TLS certificate and key"

  (application-conf-check config)
  (let* ((port (application-conf-port config))
         (cert (application-conf-cert config))
         (cert-key (application-conf-cert-key config))
         (host-name (application-conf-host-name config))
         (host-name-list (list host-name (string-append "www." host-name))))
    (service
     nginx-service-type
     (nginx-configuration
      (server-blocks
       (list
        (nginx-server-configuration
         (server-name host-name-list)
         (listen '("80"))
         (raw-content '("return 301 https://$host$request_uri;")))

        (nginx-server-configuration
         (server-name host-name-list)
         (listen '("443 ssl"))
         (ssl-certificate cert)
         (ssl-certificate-key cert-key)
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

;; SSH daemon
;; ──────────

(define (application-sshd config)
  "ApplicationConf → Service

Return an OpenSSH service configured to allow root login only via the provided
public key (password authentication is disabled)"

  (application-conf-check config)
  (let ((pub-key (application-conf-ssh-root-pub-key config)))
    (service
     openssh-service-type
     (openssh-configuration
      (permit-root-login 'prohibit-password)
      (password-authentication? #f)
      (generate-host-keys? #t)
      (authorized-keys
       `(("root" ,pub-key)))))))

;; Firewall
;; ────────

(define (application-firefwall config)
  "ApplicationConf → Service

Return an nftables firewall service with a strict input policy that allows only
SSH (port 22), HTTP/HTTPS (ports 80/443), loopback, established/related connections,
ICMP, and DHCP client replies while dropping everything else"

  (application-conf-check config)
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

;; Application service type
;; ────────────────────────

(define application-service-type
  (service-type
   (name 'application)
   (description "application")
   (extensions
    (list
     (service-extension shepherd-root-service-type application-master)
     (service-extension activation-service-type application-activation)
     (service-extension account-service-type application-accounts)))
   (default-value (application-conf))))

;; Application services
;; ────────────────────

(define (application-services config)
  "ApplicationConf → List(Service)

Return the list of all services required by the application (DHCP client,
SSH daemon, firewall, reverse proxy, main application service and database)"

  (application-conf-check config)
  (list
   (application-root config)
   (service dhcpcd-service-type)
   (application-sshd config)
   (application-firefwall config)
   (application-reverse-proxy config)
   (service application-service-type config)
   (application-database config)))

;; Application package
;; ───────────────────

(define (application-package config)
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

;; Home configurations
;; ───────────────────
;;
;; Add tools to root so that it can operate administrative tasks. Same idea for other
;; users.

(define (application-root config)
  "ApplicationConf → Service

Return a `guix-home-service-type` service that configures a comfortable
environment for the root user.  It includes Emacs together with Guile/Scheme
development tools as well as a curated selection of CLI utilities useful for
system administration, networking diagnostics, firewall management, system-log
analysis, debugging, monitoring, file management, and general server
maintenance."

  (application-conf-check config)

  (let ((host-name (application-conf-host-name config))
        (port (application-conf-port config)))
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
               (application-package config)))
             (services
              (list
               (simple-service
                'test-config
                home-xdg-configuration-files-service-type
                (list `("application-env.bash"
                        ,(plain-file "application-env.bash"
                                     (format #f "\
export PHX_SERVER=true
export XAI_API_KEY=sk-0000
export SECRET_KEY_BASE=Z8DeDEXcl3tVcyN6HfEUu60yuMUaKKX29ViWUSF0/PLgPM8DkenrHlJRBahDxUJc
export PHX_HOST=~a
export PORT=~a
" host-name port)))
                      `("start"
                        ,(plain-file "start"
                                     (format #f "\
source .config/application-env.bash
createdb -U postgres application
migrate
server
" host-name port)))))))))
      (list (application-conf-name config)
            (home-environment
             (packages
              (list
               (application-package config)))))))))

;; Operating system
;; ────────────────

(define configuration
  (application-conf
   (lang "fr")
   (name "application")
   (version "0.1.0")
   (dist cst:backend-dist)
   (ssh-root-pub-key-path cst:dev-public-key-path)))

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
   (targets '("/dev/vda"))
   (keyboard-layout keyboard-layout)))

 (file-systems
  (cons (file-system
         (mount-point "/")
         (device "/dev/vda1")
         (type "ext4"))
        %base-file-systems))

 (services
  (append (application-services configuration)
          %base-services)))
