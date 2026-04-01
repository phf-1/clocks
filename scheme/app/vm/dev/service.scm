;; Context

;; [[id:709a6ce8-29d8-4054-b578-18d6e652de50][package]] :≡ [[ref:2c987f55-f961-4d1f-9268-dee9264ce318]]
;; [[id:3d3d718d-f6e8-41f0-a565-cbdae8a7fe2d][service]] :≡ https://doc.guix.gnu.org/shepherd/latest/en/html_node/Defining-Services.html

;; Specification

;; This module exports app-service-type and app-configuration.
;; app-service-type is a [[ref:3d3d718d-f6e8-41f0-a565-cbdae8a7fe2d][service]] for [[ref:709a6ce8-29d8-4054-b578-18d6e652de50][package]]
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

(define (app-shepherd-service config)
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

(define app-service-type
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
