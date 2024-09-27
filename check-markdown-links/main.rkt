#lang racket

(provide run-checks)

(require "check.rkt"
         "options.rkt"
         threading
         file/glob)

(define extensions
    '(".markdown" ".mdown" ".mkdn"
      ".md" ".mkd" ".mdwn"
      ".mdtxt" ".mdtext" ".rmd"))

;; path -> string
;; (path-extension "foo/bar.baz") -> ".baz"
;; (path-extension "foo/bar") -> ""
;; (path-extension "foo/bar/baz.") -> "."
;; (path-extension "foo/bar/baz.buzz.bamf") -> ".bamf"
(define (path-extension path)
  (~> path
    path-get-extension
    (or #"")
    bytes->string/utf-8))

(define (markdown? path)
  (~> path
    path-extension
    string-downcase
    (member extensions)))

(define (regular-file? path)
  (~> path
    file-or-directory-stat
    (hash-ref 'mode)
    (bitwise-and regular-file-type-bits)
    zero?
    not))

(define (file-type path)
  ; file-or-directory-stat follows symbolic links
  (define mode (~> path file-or-directory-stat (hash-ref 'mode)))
  (define (mask bits) (~> mode (bitwise-and bits) zero? not))
  (cond
    [(mask regular-file-type-bits) '#:regular-file]
    [(mask directory-type-bits) '#:directory]
    [else '#:other]))

(define (walk-candidate-files dir readmes-only)
  (define visited (mutable-set))
  (define (visit? path)
    (let* ([id (file-or-directory-identity path)]
           [visited? (set-member? visited id)])
      (if visited? #f
        (begin
          (set-add! visited id)
          #t))))
  (define (keep? path)
    (and (markdown? path)
      (equal? (file-type path) '#:regular-file)
      (or (not readmes-only) (readme? path))))

  (sequence-filter keep?
    (in-directory dir visit?)))

(define (readme? path)
  (~> path
    file-name-from-path
    (path-replace-extension #"")
    path->string
    string-downcase
    (equal? "readme")))

(define (candidate-files roots readmes-only)
  (let loop ([sequences '()] [paths roots])
    (match paths
      ['() (apply in-sequences sequences)]
      [(cons root rest)
        (match (file-type root)
          [#:regular-file
           (if (or (not readmes-only) (readme? root))
            (loop (cons (in-value root) sequences) rest)
            (loop sequences rest))]
          [#:directory
           (loop (cons (walk-candidate-files root readmes-only) sequences) rest)]
          [#:other (loop sequences rest)])])))

(define (run-checks paths readmes-only output-port)
  ; Check for broken and circular hyperlinks in all markdown files at or below
  ; the specified paths.
  ; If readmes-only is not #f, consider only those regular files whose name,
  ; excluding the extension, is case insensitive equal to "readme".
  ; Print diagnostics to the specified output port for each bad link
  ; found. Return the number of bad links found.
  (for/sum ([path (candidate-files paths readmes-only)])
    (check-markdown-links path output-port)))

(define (main argv)
  (match (parse-options argv)
    [(options lint readmes-only paths)
     (let* ([output-port (if lint (current-error-port) (current-output-port))]
            [num-issues (run-checks paths readmes-only output-port)]
            [status (if lint num-issues 0)])
       (exit status))]))

; for use as a command line tool
(module+ main
  (main (current-command-line-arguments)))
