let s:plugin = maktaba#plugin#Get('aikido')

function! s:IsActiveCommitUndescribed() abort " {{{
  let empty_call = maktaba#syscall#Create([
        \'jj', 'log',
        \'--no-graph',
        \'--ignore-working-copy',
        \'--revisions', '@',
        \'--template', 'description'
      \])

  " Using wc instead of grep to avoid try/catch performance hits.
  let empty_check = maktaba#syscall#Create([
        \"wc", "-c"
        \])

  let result = l:empty_check.WithStdin(l:empty_call.Call().stdout).Call()

  return l:result.stdout == 0
endfunction
" }}}

function s:RevIsRoot(rev) " {{{
  let root_log = maktaba#syscall#Create([
        \'jj', 'log',
        \'--ignore-working-copy',
        \'--no-graph',
        \'--revisions', a:rev .. ' & root()',
        \'--template', 'commit_id'
      \])

  " Using wc instead of grep to avoid try/catch performance hits.
  let root_check = maktaba#syscall#Create([
        \"wc", "-c"
        \])

  let result = l:root_check.WithStdin(l:root_log.Call().stdout).Call()

  return l:result.stdout == 0
endfunction
" }}}

""
" @private
" Returns a list of revisions indicating a range of commits representing the
" "active" revset.
"
" In the event that we are sitting atop the target commit (in
" true-to-JJ-fashion), then this revset will return a revset indicating the
" current "working" commit as well as the target commit.  This will be done
" based on whether or not the current commit has a description or not.  If the
" current commit has no description then we assume it is related to its
" predecessor commit.  This empty-parent discovery does not cascade and
" currently only moves up to the parent and no further.
function s:LegalActiveRevset() abort " {{{
  if s:IsActiveCommitUndescribed()
    if s:RevIsRoot('@-')
      return ['@']
    endif
    return ['@-', '@']
  endif

  return ['@']
endfunction
" }}}

""
" Gets the currently important modified files.
"
" If this is run in an empty commit then the parent commit is used instead.
function! s:GetModifiedFiles(revset) abort " {{{
  let info_call = maktaba#syscall#Create([
        \'jj', 'log',
        \'--no-graph',
        \'--ignore-working-copy',
        \'--revisions', join(a:revset, '::'),
        \'--template', 'self.diff().files().map(|file| file.path().display()).join("\n")',
      \])

  return split(info_call.Call().stdout, '\n')
endfunction
" }}}

""
" A callback for the FZF modified file picker.
function! aikido#ChangeCallback(lines) " {{{
  let [command ; multi_file] = split(a:lines[0])
  let file = join(l:multi_file, ' ')

  if l:command == "enter"
    exec 'edit ' . l:file
  elseif l:command == "ctrl-s"
    exec 'vertical split ' . l:file
  elseif l:command == "ctrl-v"
    exec 'edit ' . l:file
    call aikido#Vdiff('@-')
  endif
endfunction
" }}}

""
" @public
" Returns the root of the VCS Workspace.
function! aikido#Root() abort " {{{
  return trim(maktaba#syscall#Create(['jj', 'root']).Call().stdout)
endfunction
" }}}


""
" @public
" Searches through modified and new files to find the |<cword>|, returning the
" matching lines in the quickfix window..
function! aikido#Grep(word) abort " {{{
  let files = s:GetModifiedFiles(s:LegalActiveRevset())
  execute 'vimgrep /' .. a:word .. '/g ' .. join(l:files, ' ')
  cw
endfunction
" }}}

""
" @public
" Searches through modified and new files to find a certain string, returning
" the matching lines in the quickfix window..
function! aikido#GrepPrompt() abort " {{{
  call inputsave()
  let pattern = input('pattern: ')
  call inputrestore()

  call aikido#Grep(l:pattern)
endfunction
" }}}

""
" @public
" Diffs the working copy against [revision].
"
" This is the implementation for @command(AKDiff)
" @default revision="@-"
"
function! aikido#Diff(revision = '@-', ...) abort " {{{
  let vertical = get(a:, 1, 0)
  let diff_call = maktaba#syscall#Create([
        \'jj', 'file',
        \'show',
        \'--quiet',
        \'--revision', a:revision,
        \'--',
        \expand("%")
      \])

  let content = split(diff_call.Call().stdout, '\n')
  let buffer_name = 'diff_' .. expand("%:t")

  if bufexists(l:buffer_name)
    execute 'bwipeout ' .. bufnr(l:buffer_name)
  endif

  let diff_buff = bufadd(l:buffer_name)
  call bufload(l:diff_buff)

  call deletebufline(l:diff_buff, 1, '$')
  call appendbufline(l:diff_buff, 1, l:content)
  call deletebufline(l:diff_buff, 1)

  if l:vertical
    execute 'leftabove vertical sbuffer' ..  l:diff_buff
  else
    execute 'leftabove sbuffer ' .. l:diff_buff
  endif

  setlocal bufhidden=wipe buftype=nofile

  difft
  wincmd p
  difft
endfunction
" }}}


""
" @public
" Diffs the working copy against [revision] with a vertical split.
function! aikido#Vdiff(...) abort " {{{
  let rev = get(a:, 1, '@-')
  call aikido#Diff(l:rev, 1)
endfunction
" }}}

function! aikido#AnnotateCallback(buffer, syscall) " {{{
  if a:syscall.status != 0
    execute 'silent bwipeout ' .. a:buffer

    echohl ErrMsg
    for line in split(a:syscall.stderr, '\n')
      echom l:line
    endfor
    echoerr "Annotation failed"
  else
    call setbufline(a:buffer, 1, split(a:syscall.stdout, '\n'))
  endif
endfunction
" }}}

""
" @public
" Provides annotations for each line of code and when it was last changed, the
" most recent author, etc.
function! aikido#Annotate() abort " {{{

  let first_line_template = s:plugin.Flag('annotate_hunk_first_line_template')
  let secondary_entries = s:plugin.Flag('annotate_hunk_secondary_line_templates')
  let secondary_line_template = string("")

  let full_file = expand("%:p")
  for [k, v] in items(l:secondary_entries)
    if l:full_file =~ l:k
      let secondary_line_template = l:v
      break
    endif
  endfor

  let template = 'if(' .. join([
        \'self.first_line_in_hunk()',
        \l:first_line_template,
        \l:secondary_line_template],
      \',') .. ') ++ "\n"'

  let annotate_call = maktaba#syscall#Create([
        \'jj', 'file', 'annotate',
        \'--quiet',
        \'--template', l:template,
        \'--',
        \expand("%")])

  setlocal scrollbind
  let line_count = line('$')
  let current_line = line('w0')
  let old_offset = &g:scrolloff
  let &g:scrolloff=0

  let annotate_buff = bufadd('akannotate')
  silent execute 'vert leftabove sb +vertical\ resize\ 30 ' .. l:annotate_buff
  setlocal buftype=nofile winfixwidth signcolumn=no nonumber bufhidden=wipe filetype=jjannotate syntax=ON

  call appendbufline(l:annotate_buff, 1, repeat(['-- fetching annotations --'], l:line_count - 1))
  execute 'normal! ' .. l:current_line .. 'Gzt'
  setlocal scrollbind
  :syncbind

  wincmd p
  let &g:scrolloff = l:old_offset

  call annotate_call.CallAsync(
        \maktaba#function#Create('aikido#AnnotateCallback', [l:annotate_buff]),
        \1)

endfunction
" }}}

""
" @public
" An FZF selection pop-up for files currently changed compared to the first
" parent commit.
function! aikido#Changes(...) abort " {{{
  let revset = get(a:, 1, s:LegalActiveRevset())

  let files = s:GetModifiedFiles(l:revset)

  " We always preview the file at the current commit currently.
  call fpop#Picker(l:files, #{
        \fzf_args: [
          \'--exact',
          \'--header=enter open | ^s split | ^v diff',
          \'--preview', join(s:plugin.Flag('file_preview') + ['{}'], " "),
          \'--preview-window', s:plugin.Flag('file_preview_split'),
          \'--expect=enter,ctrl-s,ctrl-v'
        \],
        \callback: function('aikido#ChangeCallback')
      \}
    \)
endfunction
" }}}

""
" @public
" Establishes a new commit with the current working changes.
function! aikido#NewCommit(bang, ...) " {{{
  let bang_args = a:bang ? ['--ignore-working-copy'] : []
    maktaba#syscall#Create(['jj', 'new'] + l:bang_args + get(a:, 0, []))
endfunction
" }}}

""
" @public
" Updates the current commit message for the working copy.  By default this also
" commits all saved buffers and not-yet-committed local changes in the typical
" JJ manner.
"
" If {bang} is provided, this will not commit the current working directory.
"
" If [rev] is not provided, it will default to the current commit.
function! aikido#Describe(bang, ...) " {{{
  let rev = get(a:, 1, '@')
  let args = [
        \'--no-patch',
        \'--template', 'builtin_draft_commit_description',
        \l:rev]

  let bang_args = a:bang ? ['--ignore-working-copy'] : []
  let message = maktaba#syscall#Create(['jj','show'] + l:bang_args + l:args)
        \.Call().stdout->split('\n')

  let desc_buf = bufadd('_aikido_desc')
  call bufload(l:desc_buf)

  call deletebufline(l:desc_buf, 1, "$")
  call appendbufline(l:desc_buf, 1, l:message)
  call deletebufline(l:desc_buf, 1)

  execute 'sbuffer ' .. l:desc_buf

  let l:old_ul = &l:undolevels
  setlocal bufhidden=wipe buftype=acwrite filetype=jjdescription undolevels=-1
  execute "silent! normal! i \<BS>"
  let &l:undolevels = l:old_ul
  setlocal nomodified

  augroup aikido_desc_close
    autocmd!

    if a:bang
      autocmd BufWriteCmd <buffer> call maktaba#syscall#Create(
            \['jj', 'describe', '--stdin', '--ignore-working-copy'])
            \.WithStdin(getline(1, '$')->filter('v:val !~ "^JJ[[:upper:]]*:"')->join("\n")).Call()
    else
      autocmd BufWriteCmd <buffer> call maktaba#syscall#Create(
            \['jj', 'describe', '--stdin'])
            \.WithStdin(getline(1, '$')->filter('v:val !~ "^JJ[[:upper:]]*:"')->join("\n")).Call()
    endif

    autocmd BufWriteCmd <buffer> setlocal nomodified
  augroup END

endfunction
" }}}

""
" @private
" Shows the current jj graph in a separate window.aikido:plugin[mappings]aikido:plugin[mappings]
function! aikido#ShowLog() " {{{
  let message = maktaba#syscall#Create(['jj', '--ignore-working-copy', 'log', '--color=never',
        \'--template', 'separate(" ", change_id.short(), author.name(), bookmarks, tags, description.first_line(), commit_id.short())'])
        \.Call().stdout->split('\n')

  if exists("s:graph_buf")
    bwipeout '_aikido_graph'
  endif

  let s:graph_buf =  bufadd('_aikido_graph')
  call bufload(s:graph_buf)

  call deletebufline(s:graph_buf, 1, "$")
  call appendbufline(s:graph_buf, 1, l:message)
  call deletebufline(s:graph_buf, 1)
endfunction
" }}}

""
" @private
" Changes the current commit based on a the graph <line> and the requested <action>.
function! aikido#ChangeCommit(action) " {{{
  let commit = aikido#ExtractCommit()->split(' ')[-1]

  call maktaba#syscall#Create(['jj', a:action, l:commit]).Call()
  call aikido#ShowLog()
endfunction
" }}}

""
" @private
" Extracts the commit from a hilighted line in the current buffer.
function! aikido#ExtractCommit() " {{{
  let line_num = line(".")
  let commit = getline(l:line_num)->split(' ')[-1]

  if len(l:commit) < 5
    let commit = getline(l:line_num - 1)->split(' ')[-1]
  endif

  return l:commit
endfunction
" }}}

""
" @public
" Shows the commit graph for this repository.
"
" This graph is interactive and can switch to a different commit by selecting
" with the cursor.  <Enter> will select the highlighted commit and make it the
" new active commit.  <n> will create a new commit atop the highlighted commit
" and <d> will modify the description of the highlighted commit (experimental).
function! aikido#Graph() " {{{
  call aikido#ShowLog()

  execute 'sbuffer ' .. s:graph_buf

  setlocal bufhidden=wipe buftype=nowrite readonly filetype=jjlog syntax=ON

  map <buffer> <Enter> :call aikido#ChangeCommit('edit')<CR>
  map <buffer> n :call aikido#ChangeCommit('new')<CR>
  map <buffer> d :call aikido#Describe(1, aikido#ExtractCommit()) \| call aikido#ShowLog()<CR>
endfunction
" }}}

""
" @public
" Updates the working copy and then uploads the current commit.
"
" This literally calls upload with no arguments at this point in time, nothing
" more, nothing less.
function! aikido#Upload() " {{{
  call maktaba#syscall#Create(['jj', 'upload']).Call()
endfunction
" }}}
