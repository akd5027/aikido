syntax keyword JjAuthor alphalex
syntax match JjTag /cl\/[[:digit:]]*\**/
syntax match JjCurrentCommit /@/
syntax match JjGraphPath /│/
syntax match JjGraphPath /├/
syntax match JjGraphPath /─/
syntax match JjGraphPath /╯/
syntax match JjConflict /×/
syntax match JjRoot /◆/

hi JjCurrentCommit ctermfg=green
hi JjAuthor ctermfg=blue
hi JjGraphPath ctermfg=gray
hi JjTag ctermfg=green
hi JjConflict ctermfg=red
hi JjRoot ctermfg=blue
