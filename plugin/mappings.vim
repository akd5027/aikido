let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

let s:prefix = s:plugin.MapPrefix('a')

" Diffs the working file vertically against its state in the first ancestors
" version.
execute 'nnoremap <unique> <silent>' s:prefix . 'v' ':AKVdiff<CR>'

" Diffs the working file horizontally against its state in the first ancestors
" version.
execute 'nnoremap <unique> <silent>' s:prefix . 'd' ':AKDiff<CR>'

" Opens an FZF popup allowing for selection of a file already modified in the
" current commit.  The selected file will be opened for editing.
execute 'nnoremap <unique> <silent>' s:prefix . 'p' ':AKChanges<CR>'

" Updates the existing description for the current commit.
execute 'nnoremap <unique> <silent>' s:prefix . 'x' ':AKDescribe<CR>'
