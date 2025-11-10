let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

let s:prefix = s:plugin.MapPrefix('a')

" Diffs the working file vertically against its state in the first ancestor's
" version.
execute 'nnoremap <unique> <silent>' s:prefix . 'v' ':AKVdiff<CR>'

" Diffs the working file vertically against its state in the first
" grand-ancestor's version.
execute 'nnoremap <unique> <silent>' s:prefix . 'V' ':AKVdiff<CR> @--'

" Diffs the working file horizontally against its state in the first ancestor's
" version.
execute 'nnoremap <unique> <silent>' s:prefix . 'd' ':AKDiff<CR>'

" Diffs the working file horizontally against its state in the first
" grand-ancestor's version.
execute 'nnoremap <unique> <silent>' s:prefix . 'D' ':AKDiff<CR> @--'

" Opens an FZF popup allowing for selection of a file already modified in the
" current commit.  The selected file will be opened for editing.
execute 'nnoremap <unique> <silent>' s:prefix . 'p' ':AKChanges<CR>'

" Updates the existing description for the current commit.
execute 'nnoremap <unique> <silent>' s:prefix . 'x' ':AKDescribe<CR>'

" Shows the JJ Graph at the current revision.  This is an interactive graph
" that allows different commits to be selected with the cursor.
execute 'nnoremap <unique> <silent>' s:prefix . 'a' ':AKGraph<CR>'

" Searches for a prompted phrase within the current commit.
execute 'nnoremap <unique> <silent>' s:prefix . 'g' ':AKGrep<CR>'

" Searches for a <cword> within the current commit.
execute 'nnoremap <unique> <silent>' s:prefix . 'h' ':AKGrepCword<CR>'
