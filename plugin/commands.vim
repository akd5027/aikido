let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Diffs the working file against a specific revision.
"
" This command does a horizontal split when opening the new diff.
command -nargs=? AKDiff call aikido#Diff(<f-args>)

""
" Diffs the working file against a specific [revision].
"
" This command does a vertical split when opening the new diff.
" @default revision="@-"
command -nargs=? AKVdiff call aikido#Vdiff(<f-args>)

""
" Shows changed files in the [commit].
"
" If the requested commit is empty then the first ancestor is checked for
" changes as well.  This function does not check deeper than the first
" ancestor.
" @default commit=\@
"
command -nargs=? AKChanges call aikido#Changes(<f-args>)

""
" Greps for a prompt-provided string in all files represented by the current
" commit.
"
" If the current commit is empty then th eparent commit is checked.  Grepping
" is done using :vimgrep.
command AKGrep call aikido#GrepPrompt()

""
" Greps for the word under the cursor in all files represented by the current
" commit.
"
" If the current commit is empty then th eparent commit is checked.  Grepping
" is done using :vimgrep.
command AKGrepCword call aikido#Grep(expand("<cword>"))
