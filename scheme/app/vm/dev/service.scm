;; [[id:ab47a8e4-aaa3-431d-8a50-30b47c36d762][AppService]]
;;
;; This module exports a shepherd service and service configuration for the app
;; app-service-type is a [[ref:c12b81b0-eeeb-46de-9c1e-26d5113cbfdd][ShepherdService]] for [[ref:65e6819a-31da-4ba2-a6cb-f1ee97c06020][GuixPackage]]
;; app-configuration provides a default configuration and configuration options

;; Implementation

(define-module (app vm dev service))

(use-modules
 (guix records)
 (guix gexp)
 (gnu services)
 (gnu services shepherd)
 (srfi srfi-1))

(define-record-type* <app-configuration>
  app-configuration make-app-configuration
  app-configuration?
  (pid-file  app-configuration-pid-file  (default "/var/run/app.pid"))
  (name      app-configuration-name      (default "joe")))

(define-public (app-shepherd-service config)
  "Return a list of <shepherd-service> for app with CONFIG."
  (let ((pid-file (app-configuration-pid-file config))
        (name     (app-configuration-name config)))
    (list (shepherd-service
           (documentation "App server.")
           (requirement '(user-processes loopback))
           (provision '(app))
           (start #~(make-forkexec-constructor
                     (list "/bin/sh" "-c"
                           (string-append "while true; do echo 'hello " #$name "'; sleep 1; done"))
                     #:pid-file #$pid-file))
           (stop #~(make-kill-destructor))
           (auto-start? #t)))))

(define-public app-service-type
  (service-type
   (name 'app)
   (description "Run the app.")
   (extensions
    (list (service-extension
           shepherd-root-service-type
           app-shepherd-service)))
   (default-value (app-configuration))))

;; Interface

(export app-service-type)
(export app-configuration)
(export app-configuration-name)
(export app-configuration-pid-file)
