#lang racket

(provide run-checks)

(require "check.rkt"
         "options.rkt"
         threading
         file/glob)

(define extensions
  (map
    (lambda (without-dot) (~a "." without-dot))
    '("markdown" "mdown" "mkdn" "md" "mkd" "mdwn" "mdtxt" "mdtext" "Rmd")))

(define (markdowns stems)
  ; Return a list of file path base names having the specified stems and the
  ; supported markdown extensions, e.g. 
  ;
  ;       (markdowns '("readme" "README"))
  ;    -> '("readme.md" "README.md" "readme.markdown" "README.markdown" ...)
  (append
    (for*/list ([extension extensions]
                [stem stems])
      (~a stem extension))))

(define (glob-patterns paths stems)
  ; Return a sequence of glob patterns describing possible markdown files at
  ; and under the specified paths, where the markdown files have the specified
  ; stems, e.g.
  ;
  ;        (glob-patterns '("../") '("README" "readme"))
  ;     -> (stream "../README.md" "../**/README.md" "../readme.mdtxt" ...)
  ;
  ;        (glob-patterns '("./" "../") '("*"))
  ;     -> (stream "./*.md" "./*.mdtxt" ... "../*.md" "../**/*.md" ...)
  (apply 
    sequence-append
    (for/list ([path paths])
      (cond
        ; A regular file is its own glob pattern.
        [(file-exists? path) (stream path)]

        ; A search children of the directory for readme files, and then search
        ; recursively in any subdirectories.
        [(directory-exists? path)
         (let ([base-names (markdowns stems)])
           (stream-append 
             (for/stream ([base-name base-names])
               (build-path path base-name))
             (for/stream ([base-name base-names]) 
               (build-path path "**" base-name))))]

        ; Path doesn't refer to a regular file or a directory, so error.
        [else
         (raise-user-error (~a "Specified path " path " doesn't exist."))]))))

(define (run-checks paths stems output-port)
  ; Check for broken and circular hyperlinks in all markdown files having the
  ; specified file name stems (e.g. "readme") at and under the specified
  ; paths. Print diagnostics to the specified output port for each bad link
  ; found. Return the number of bad links found. Note that stems are the part
  ; of the file base names without the extension, since this module appends
  ; each of the supported markdown file extensions.
  (for/sum ([path (~> paths (glob-patterns stems) sequence->list in-glob)])
    ; The contract of in-glob says that it takes a sequence, but in fact it
    ; must be a list.
    (check-markdown-links path output-port)))

(define (main argv)
  (match (parse-options argv)
    [(options lint readmes-only paths)
     (let* ([stems (if readmes-only '("readme" "README" "Readme") '("*"))]
            [output-port (if lint (current-error-port) (current-output-port))]
            [num-issues (run-checks paths stems output-port)]
            [status (if lint num-issues 0)])
       (exit status))]))

; for use as a command line tool
(module+ tool
  (main (current-command-line-arguments)))
