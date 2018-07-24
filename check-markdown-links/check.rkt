#lang racket

(provide check-markdown-links)

(require racket/generator
         markdown
         xml/path
         threading)

(struct link-issue (href why) #:transparent)

(define (wrap-xexprs xexprs)
  ; Splice the specified list of xexprs into a list whose first element is
  ; 'html. This procedure exists because parse-markdown returns a list of
  ; xexprs, which itself is not a valid xexpr until wrapped.
  `(html ,@xexprs))

(define (hrefs xexpr)
  ; Return a list containing the value of each href attribute in the
  ; specified xexpr.
  (se-path*/list '(a #:href) xexpr))

(define (parent-directory path)
  ; Return a value representing the parent directory of the specified path,
  ; where the value returned is suitable for use as an argument to build-path.
  (let-values ([(directory basename _) (split-path path)])
    (if (equal? directory 'relative)
      'same
      directory)))

(define (refer-to-same-file? left-path right-path)
  ; Return whether the two specified paths refer to the same file.
  (equal? (file-or-directory-identity left-path)
          (file-or-directory-identity right-path)))

(define begins-like-uri
  ; Return whether the specified path string begins like a URI, e.g. http://...
  (let ([beginning-regexp (pregexp "^\\w+:")])
    (lambda (path)
      (regexp-match beginning-regexp path))))

(define (markdown-link-issues path)
  ; Return a generator that yields link-issue values found in the specified
  ; markdown file.
  (generator ()
    (let ([dir (parent-directory path)])
      (for ([href (~> path parse-markdown wrap-xexprs hrefs)])
        ; Don't bother with real URIs (even if they're file://). I'm
        ; interested only in relative paths. Note that this is a lossy
        ; assumption, because "http://www.google.com" could be a relative
        ; path; namely, (build-path "http:" "www.google.com"). I ignore this
        ; possibility.
        (unless (begins-like-uri href)
          (let ([combined-path (build-path dir href)])
            (cond
              ; If it's a file, fine, but if it's the same file as the markdown
              ; file, that's probably not intended.
              [(file-exists? combined-path)
               (when (refer-to-same-file? combined-path path)
                 (yield (link-issue href 
                          (~a "The file contains a hyperlink to itself."))))]
  
              ; If it doesn't otherwise exist, that's an error.
              [(not (or (directory-exists? combined-path)
                        (link-exists? combined-path)))
               (yield (link-issue href
                        "The referenced path doesn't exist."))])))))))

(define (check-markdown-links path output)
  ; Print to the specified output port a diagnostic for each link issue found
  ; in the markdown file at the specified path. Return the number of issues
  ; found.
  (for/sum ([issue (in-producer (markdown-link-issues path) (void))])
    (match issue
      [(link-issue href why)
       (displayln 
         (~a "The markdown file " path " references " href 
           " which is problematic because: " why)
         output)
       1]))) ; sum ... 1 -> so this procedure returns the number of issues.
