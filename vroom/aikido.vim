Loading the plugin manually.

  :set nocompatible
  :let g:helloworlddir = fnamemodify($VROOMFILE, ':p:h:h')
  :let g:bootstrapfile = g:helloworlddir . '/bootstrap.vim'
  :execute 'source' g:bootstrapfile

  :call maktaba#LateLoad()

Now we'll try loading the root of the repository.  This should fail since we
are not in a repository yet.

  :call aikido#GetRoot()
  ~ Error: There is no jj repo in "."

Now if we create a fake Jujutsu repository we should be able to acquire the root.

  :call aikido#GetRoot()
  ! jj root
  $ echo "/some/repo/"
  ~ /some/repo/
