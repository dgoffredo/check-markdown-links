#lang info

(define name "check-markdown-links")

(define deps '("racket" "markdown"))

(define raco-commands 
  '(("check-markdown-links"                  ; command
     (submod check-markdown-links tool)      ; module path
     "check markdown files for broken links" ; description
     #f)))                                   ; prominence (#f -> hide)
