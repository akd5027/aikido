if exists("b:current_syntax") | finish | endif
if !exists("syntax_on") | finish | endif

syntax region JjHunk 
      \ start=/^\s+\s/
      \ end=/$/
      \ contains=JjHunkCommit
      \ display
      \ keepend

syntax match JjHunkCommit contained /^\s*+\s[g-z]\+/
      \ containedin=JjHunk

" Define syntax match for the Author (the second word)
" /^\s*+\s\+\S\+\s\+/ matches up to and including the space after the first word.
" \zs starts the highlight for the second word.
" \S\+ matches the author's name (e.g., "alphalex").
" \ze ends the highlight.
syntax match JjHunkAuthor contained /\S\+/
      \ containedin=JjHunk

" --- Highlight Definitions ---
hi JjHunkCommit ctermfg=green
hi JjHunkAuthor ctermfg=blue
