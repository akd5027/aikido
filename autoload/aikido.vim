let s:plugin = maktaba#plugin#Get('aikido')

""
" Gets the currently important modified files.
"
" If this is run in an empty commit then the parent commit is used instead.
function! s:GetModifiedFiles(...) abort
  let rev = get(a:, 1, '@')
  let info_call = maktaba#syscall#Create([
        \'jj', 'log',
        \'--no-graph',
        \'--ignore-working-copy',
        \'--revisions=' .. l:rev,
        \'--template=self.diff().files().map(|file| file.path().display()).join("\n")',
      \])

  return split(info_call.Call().stdout, '\n')
endfunction

function! s:GetRecentModifiedFiles(rev) abort
  let rev = a:rev
  let files = s:GetModifiedFiles(l:rev)

  if a:rev != '@-' && empty(l:files)
    let rev = '@-'
    let files = s:GetModifiedFiles(l:rev)
  endif

  return [l:rev, l:files]
endfunction

""
" A callback for the FZF modified file picker.
function! aikido#ChangeCallback(lines)
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

""
" @public
" Returns the root of the VCS Workspace.
function! aikido#Root() abort
  return trim(maktaba#syscall#Create(['jj', 'root']).Call().stdout)
endfunction


""
" @public
" Searches through modified and new files to find the |<cword>|, returning the
" matching lines in the quickfix window..
function! aikido#Grep(bang, word) abort
  let [rev, files] = s:GetRecentModifiedFiles(a:bang ? '@-' : '@')
  execute 'vimgrep /' .. a:word .. '/g ' .. join(l:files, ' ')
  :cw
endfunction

""
" @public
" Searches through modified and new files to find a certain string, returning
" the matching lines in the quickfix window..
function! aikido#GrepPrompt(bang) abort
  call inputsave()
  let pattern = input('pattern: ')
  call inputrestore()

  call aikido#Grep(a:bang, l:pattern)
endfunction

""
" @public
" Diffs the working copy against [revision].
"
" This is the implementation for @command(Akdiff)
" @default revision="@-"
"
function! aikido#Diff(...) abort
  let rev = get(a:, 1, '@-')
  let vertical = get(a:, 2, 0)
  let content = systemlist('jj file show --quiet --revision=' .. l:rev .. ' -- ' .. expand("%"))
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


""
" @public
" Diffs the working copy against [revision] with a vertical split.
function! aikido#Vdiff(...) abort
  let rev = get(a:, 1, '@-')
  call aikido#Diff(l:rev, 1)
endfunction

""
" @public
" Provides annotations for each line of code and when it was last changed, the
" most recent author, etc.
function! aikido#Annotate() abort
  let content = systemlist('jj file annotate --quiet -T "if(self.first_line_in_hunk(), commit.change_id().short(7) ++ \" \" ++ commit.author().email().local()) ++ \"\n\"" -- ' .. expand("%"))
  let blame_buff = bufadd('akblame')

  silent execute 'topleft vert sb +vertical\ resize\ 30 ' .. l:blame_buff

  call appendbufline(l:blame_buff, 1, l:content)
  call deletebufline(l:blame_buff, 1)

  setlocal buftype=nofile bufhidden=wipe
  wincmd p
  setlocal scrollbind

endfunction

""
" @public
" An FZF selection pop-up for files currently changed compared to the first
" parent commit.
function! aikido#Changes(...) abort
  let [rev, files] = s:GetRecentModifiedFiles(get(a:, 1, '@'))

  call fpop#Picker(l:files, #{
        \fzf_args: [
          \'--exact',
          \'--header=enter open | ^s split | ^v diff',
          \'--preview=jj file show -r ' .. l:rev ..' {}',
          \'--preview-window=' .. s:plugin.Flag('file_preview_split'),
          \'--expect=enter,ctrl-s,ctrl-v'
        \],
        \callback: function('aikido#ChangeCallback')
      \}
    \)
endfunction

""
" @public
" Establishes a new commit with the current working changes.
"
" CURRENTLY A WORK-IN-PROGRESS
function! aikido#NewCommit(...)
    maktaba#syscall#Create(['jj', 'new'] + get(a:, 0, []))
endfunction

""
" @public
" Updates the current commit message for the working copy.  By default this also
" commits all saved buffers and not-yet-committed local changes in the typical
" JJ manner.
"
" If [revisions] is not provided, it will default to the current commit.
"
" If [bang] is provided, this will not commit the current working directory.
function! aikido#Describe(bang, ...)
  let rev = get(a:, 1, '@')

  let args = [
        \'--no-patch',
        \'--template=builtin_draft_commit_description',
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

  setlocal bufhidden=wipe buftype=acwrite filetype=jjdescription autowrite

  augroup aikido_diff_close
    autocmd!

    if a:bang
      autocmd BufWriteCmd <buffer> call maktaba#syscall#Create(
            \['jj', 'describe', '--stdin', '--ignore-working-copy'])
            \.WithStdin(getline(1, '$')->join("\n")).Call()
    else
      autocmd BufWriteCmd <buffer> call maktaba#syscall#Create(
            \['jj', 'describe', '--stdin'])
            \.WithStdin(getline(1, '$')->join("\n")).Call()
    endif
  augroup END

endfunction

""
" @private
" Shows the current jj graph in a separate window.aikido:plugin[mappings]aikido:plugin[mappings]
function! aikido#ShowLog()
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

""
" @private
" Changes the current commit based on a the graph <line> and the requested <action>.
function! aikido#ChangeCommit(action)
  let commit = aikido#ExtractCommit()->split(' ')[-1]

  call maktaba#syscall#Create(['jj', a:action, l:commit]).Call()
  call aikido#ShowLog()
endfunction

""
" @private
" Extracts the commit from a hilighted line in the current buffer.
function! aikido#ExtractCommit()
  let line_num = line(".")
  let commit = getline(l:line_num)->split(' ')[-1]

  if len(l:commit) < 5
    let commit = getline(l:line_num - 1)->split(' ')[-1]
  endif

  return l:commit
endfunction

""
" @public
" Shows the commit graph for this repository.
"
" This graph is interactive and can switch to a different commit by selecting
" with the cursor.  <Enter> will select the highlighted commit and make it the
" new active commit.  <n> will create a new commit atop the highlighted commit
" and <d> will modify the description of the highlighted commit (experimental).
function! aikido#Graph()
  call aikido#ShowLog()

  execute 'sbuffer ' .. s:graph_buf

  setlocal bufhidden=wipe buftype=nowrite readonly filetype=jjlog syntax=ON

  map <buffer> <Enter> :call aikido#ChangeCommit('edit')<CR>
  map <buffer> n :call aikido#ChangeCommit('new')<CR>
  map <buffer> d :call aikido#Describe(1, aikido#ExtractCommit()) \| call aikido#ShowLog()<CR>
endfunction

""
" @public
" Updates the working copy and then uploads the current commit.
"
" This literally calls upload with no arguments at this point in time, nothing
" more, nothing less.
function! aikido#Upload()
  call maktaba#syscall#Create(['jj', 'upload']).Call()
endfunction
