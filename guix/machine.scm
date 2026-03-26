(define-module (clocks machine)
  #:use-module (gnu)
  #:use-module (gnu machine)
  #:use-module (gnu machine ssh)
  #:use-module (clocks oses)
  #:export (%init-machine))

(use-service-modules networking ssh)

(define %init-machine
  (machine
   (operating-system
    %init-os)
   (environment
    managed-host-environment-type)
   (configuration
    (machine-ssh-configuration
     (host-name "localhost")
     (user "root")     
     (identity "./id_ed25519")     
     (system "x86_64-linux")))))
