;; guix time-machine -C scheme/clocks/channels.scm -- deploy scheme/clocks/deploy/deploy-2.scm
(define-module (clocks deploy deploy-2))

(use-modules
 ((clocks constant) #:prefix cst:)
 (clocks os os-13)
 (gnu machine)
 (gnu machine ssh))

(define-public deploy-2
  (list
   (machine
    (operating-system os-13)
    (environment managed-host-environment-type)
    (configuration
     (machine-ssh-configuration
      (host-name "127.0.0.1")
      (port 2222)
      (system "x86_64-linux")
      (host-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tZFufL4xh0/1fW3yVQBiTzCA9RjjexkSR0VIZ3KZ+"))))))

deploy-2
