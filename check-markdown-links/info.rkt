#lang info

(define name "check-markdown-links")

(define deps '("racket" "markdown" "threading-lib"))

(define raco-commands 
  '(("check-markdown-links"                  ; command
     (submod check-markdown-links main)      ; module path
     "check markdown files for broken links" ; description
     #f)))                                   ; prominence (#f -> hide)
