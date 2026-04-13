;; [[id:d02b3b96-a92b-4dd4-b0c3-f804abe14592][os-16]]
;;
;; Minimal OS to initialize a DigitalOcean Droplet from a custom image:
;; build the disk image (e.g. `guix system image -t qcow2 os-16.scm`),
;; upload as Custom Image (raw/qcow2 supported), then create Droplet from it.
;; Requires cloud-init for full DO features (SSH keys, metadata, etc.).

(define-module (clocks os os-16))

(use-modules
 ((clocks constant) #:prefix cst:)
 (gnu packages base)
 (gnu packages python-web)   ; for python-cloud-init
 (gnu packages ssh)
 (gnu services base)
 (gnu services networking)
 (gnu services ssh)
 (gnu system)
 (gnu system locale)
 (gnu)
 (guix gexp))

(define-public os-16
  (operating-system
   (host-name "os-16")
   (timezone "Etc/UTC")

   ;; begin Minimal locale
   (locale "C.UTF-8")
   (locale-libcs (list glibc))
   (locale-definitions (list (locale-definition (source "C") (name "C.UTF-8"))))
   (keyboard-layout (keyboard-layout "fr"))
   ;; end

   ;; begin DigitalOcean conventions
   ;; (matches DO's /dev/vda presentation for custom images)
   (bootloader
    (bootloader-configuration
     (bootloader grub-bootloader)
     (targets '("/dev/vda"))
     (terminal-outputs '(console))
     (keyboard-layout keyboard-layout)))
   (file-systems
    (cons (file-system
           (device "/dev/vda1")
           (mount-point "/")
           (type "ext4"))
          %base-file-systems))
   ;; end

   (packages (cons* python-cloud-init openssh %base-packages))
   (services
    (cons*
     ;; Cloud-init config: prioritize ConfigDrive (DO metadata) before NoCloud
     ;; This prevents the "Droplets created from your image will not function properly" error.
     (extra-special-file "/etc/cloud/cloud.cfg.d/99-digitalocean.cfg"
       (plain-file "99-digitalocean.cfg"
         "datasource_list: [ ConfigDrive, NoCloud ]\n"))

     (service dhcpcd-service-type
              (dhcpcd-configuration
               (static '("domain_name_servers=1.1.1.1"))))
     (service openssh-service-type
              (openssh-configuration
               (permit-root-login 'prohibit-password)
               (authorized-keys
                `(("root" ,(local-file cst:dev-public-key-path))))))
     (modify-services %base-services
                      (guix-service-type
                       config =>
                       (guix-configuration
                        (inherit config)
                        (authorized-keys
                         (cons (local-file "/etc/guix/signing-key.pub")
                               (guix-configuration-authorized-keys config))))))))))

os-16
