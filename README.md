# Aikido

Aikido is a Jujutsu plugin for Vim. This plugin is somewhat youthful but it
provides a reasonable starting point for JJ-related convenience interactions.

## Dependencies

This plugin requires you to additionally have the following plugins also
installed:

*   `akd5027/fpop.git`

And you will want the following CLI binaries available for usage:

*   fzf

FZF can be installed through your local package manager, while the other is just
another github repository you can ensure is present in your loaded plugins.

## Main Commands

Command      | Description
:----------- | :-----------
`:AKChanges` | Shows all currently changed files in your working commit. If your working commit is empty then the parent commit will be checked instead.
`:AKVdiff`   | Takes the current file and diffs it against the parent commit. If this command takes additional arguments that can be provided to the `jj file show` command to manipulate the version you diff against.

You can map these on your own in your vimrc file.

Run `:help aikido` for more guidance and for new commands.
