(use-modules  
 (gnu machine)
 (gnu machine ssh))

(define os (load (getenv "OS_PATH")))
(define host-key (getenv "HOST_KEY"))
(define ssh-port (string->number (getenv "HOST_PORT_SSH")))

(define deployment
  (list
    (machine
      (operating-system os)
      (environment managed-host-environment-type)
      (configuration
        (machine-ssh-configuration
          (host-name "127.0.0.1")
          (system "x86_64-linux")
          (port ssh-port)
          (host-key host-key))))))

deployment
