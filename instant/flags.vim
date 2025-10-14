""
" @section Configuration, config
" Flags that control the internal behavior of Aikido.
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" Determines if the Aikido change-splits occur vertically or horizonally.
" Allowable values include:
"
" * 'top'
" * 'bottom'
" * 'left'
" * 'right'
"
" Vertical split results in a side-by-side preview, while a horizontal split
" results in a top-and-bottom preview.
call s:plugin.Flag('file_preview_split', 'right')
