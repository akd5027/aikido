""
" @section Configuration, config
" Flags that control the internal behavior of Aikido.
let [s:plugin, s:enter] = maktaba#plugin#Enter(expand('<sfile>:p'))
if !s:enter
  finish
endif

""
" During annotation, this template is used for JJ expression of the the first
" line of each hunk when `jj file annotate` is called on a file.
call s:plugin.Flag('annotate_hunk_first_line_template', '" + " ++ join(" ", commit.change_id().short(7), commit.author().email().local())')


""
" During annotation, this template is used for lines that are not the first hunk
" of an difference block.
call s:plugin.Flag('annotate_hunk_secondary_line_templates', {})
