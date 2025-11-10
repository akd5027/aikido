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
" If the current commit is empty then the parent commit is checked.  Grepping
" is done using :vimgrep.
command -bang AKGrep call aikido#GrepPrompt(<bang>0)

""
" Greps for the word under the cursor in all files represented by the current
" commit.
"
" If the current commit is empty then th eparent commit is checked.  Grepping
" is done using :vimgrep.
command -bang AKGrepCword call aikido#Grep(<bang>0, expand("<cword>"))

""
" Modifies or creates a description for the current commit.
"
" If invoked with [!] then the description will not commit the working copy.
"
" If [revision] is provided, then the description for the provided commit will
" be altered instead.
command -nargs=? -bang AKDesc call aikido#Describe(<bang>0, <f-args>)

""
" Opens an interactive JJ log graph.
"
" * <Enter> will 'edit' the commit beneath the cursor.
" * <n> will add a 'new' commit atop the commit beneath the cursor.
" * <d> will edit the description of the commit beneath the cursor. (experimental>
command AKGraph call aikido#Graph()

""
" Updates and uploads the current commit.
command JjUpload call aikido#Upload()
