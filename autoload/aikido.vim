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

function! s:GetRecentModifiedFiles() abort
  let rev = '@'
  let files = s:GetModifiedFiles(l:rev)

  if empty(l:files)
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
function! aikido#Grep(word) abort
  let [rev, files] = s:GetRecentModifiedFiles()
  execute 'vimgrep /' .. a:word .. '/g ' .. join(l:files, ' ')
  :cw
endfunction

""
" @public
" Searches through modified and new files to find a certain string, returning
" the matching lines in the quickfix window..
function! aikido#GrepPrompt() abort
  call inputsave()
  let pattern = input('pattern: ')
  call inputrestore()

  call aikido#Grep(l:pattern)
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
    execute 'vertical sbuffer' ..  l:diff_buff
  else
    execute 'sbuffer ' .. l:diff_buff
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
function! aikido#Changes() abort
  let [rev, files] = s:GetRecentModifiedFiles()

  call fpop#Picker(l:files, #{
        \fzf_args: [
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
" Updates the current commit message for the working copy.
"
" CURRENTLY A WORK-IN-PROGRESS
function! aikido#Describe(...)
  let message = get(a:, 0, v:none)

  if l:message != v:none
    let desc_func = maktaba#syscall#Create(['jj', 'describe', '--message', l:message])
  else
    let desc_func = maktaba#syscall#Create(['jj', 'describe'])
  endif

  l:desc_func.Call()

endfunction
