#lang racket

(provide (struct-out options)
         parse-options)

(struct options (lint         ; boolean: run as a linter tool
                 readmes-only ; boolean: consider README-looking files only
                 paths)       ; (list path?): files/directories to check
        #:transparent)

(define (parse-options argv)
  (define readmes-only (make-parameter #f))
  (define lint         (make-parameter #f))
  (define paths
    (command-line
      #:program "check-markdown-links"
      #:argv argv
      #:once-each
      [("--readmes-only") "Consider files with /README/i stems only"
                          (readmes-only #t)]
      [("--lint") "Fail when bad links are found, and print to standard error"
                  (lint #t)]
      #:args search-paths
      search-paths))

  (options 
    (lint) 
    (readmes-only) 
    (if (empty? paths) (list (build-path ".")) paths))) ; default to $(pwd)
