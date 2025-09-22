""
" @section Configuration, config
" Flags that control the internal behavior of Aikido.
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif
