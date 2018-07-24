![check-markdown-links](check-markdown-links.png)

check-markdown-links
====================
Check markdown files for broken relative links.

Why
---
When I move source code around within a respository, I often forget to update
links that referred to the moved code.

What
----
`check-markdown-links` is a Racket package (and `raco` command) that checks
optionally specified markdown files for broken or circular relative links (as
are supported by github).

How
---
Here's a usage example:

    $ raco check-markdown-links ~/dev/stag
    The markdown file /home/david/dev/stag/CREDIT.md references
    src/sxml-match which is problematic because: The referenced path doesn't
    exist.
    The markdown file /home/david/dev/stag/src/stag/options/README.md
    references README.md which is problematic because: The file contains a
    hyperlink to itself.
    The markdown file /home/david/dev/stag/src/stag/python/README.md
    references ../stag/stag.rkt which is problematic because: The referenced
    path doesn't exist.
    The markdown file /home/david/dev/stag/src/stag/python/README.md
    references python.rkt which is problematic because: The referenced path
    doesn't exist.
    The markdown file /home/david/dev/stag/src/stag/version/README.md
    references .githooks/README.md which is problematic because: The
    referenced path doesn't exist.

See `make help` for build/test information.

Test
----
This [link](README.md) refers to this file, and so will produce an error. This
[link](sdkfjalsdfklj) refers to a file that doesn't (shouldn't) exist, and so
will also produce an error. But [this](check-markdown-links/check.rkt) is fine
because it refers to a file that exists. [This](check-markdown-links) is also
fine, because it refers to a directory that exists.

More
----
The default behavior is to print diagnostics to standard output and return
status zero, or return a nonzero status only if an error occurs.

When the `--lint` option is specified, the behavior is to print diagnostics
to standard error and return status zero only if no diagnostics are printed,
or return a nonzero status if diagnostics are printed or if an error occurs.

Specify a list of files or directories. Files listed will be checked, while
directories listed will be recursively searched for markdown files to be
checked. If no paths are specified, the current working directory will be
searched.

When a directory is "searched for markdown files," any normal file having on
of the following extensions, or any link having one of the following
extensions and referring to a normal file, is considered: 
- .markdown
- .mdown
- .mkdn
- .md
- .mkd
- .mdwn
- .mdtxt
- .mdtext
- .Rmd

When the `--readmes-only` option is specified, only normal files named
"README<ext>" or links named "README<ext>" referring to normal files will be
considered, where "<ext>" is any of the file extensions above.