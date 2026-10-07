# proto-dotfiles-gitbash

A small, standalone setup for [Git Bash](https://gitforwindows.org/) on Windows:
a plain Bash configuration and a Vim configuration tuned for keeping a diary.
No external Vim plugins, no symlinks.

## Layout

```
bash/bashrc           Bash settings and the `diary` command
vim/vimrc             Vim settings
vim/plugin/diary.vim  diary commands (part of this repository, not an external plugin)
install.sh            hooks the above into ~/.bashrc and ~/.vimrc
```

## Install

Clone the repository anywhere and run the installer from Git Bash:

```bash
git clone https://github.com/hypatia-tile/proto-dotfiles-gitbash.git ~/proto-dotfiles-gitbash
~/proto-dotfiles-gitbash/install.sh
```

The installer creates no symlinks (Windows does not allow them by default). It
appends one line to each file instead:

- `~/.bashrc` gets `source "<repo>/bash/bashrc"`
- `~/.vimrc` gets `source <repo>/vim/vimrc`, and that vimrc adds `<repo>/vim`
  to Vim's `runtimepath`, so `~/.vim` is never touched
- `~/.bash_profile` is created to source `~/.bashrc` if it does not exist yet

Edits in the repository take effect in the next shell or Vim session. To
uninstall, delete those lines.

Vim keeps its swap and undo files in `~/.cache/vim`, so they never end up next
to diary entries.

## Diary

The diary lives outside this repository. By default it is `~/diary`. To use a
different directory (for example one synced by a cloud drive, or its own Git
repository), set `DIARY_DIR` in `~/.bashrc` **above** the `source` line:

```bash
export DIARY_DIR="/c/Users/me/Documents/diary"
```

Use the `/c/...` form rather than `C:\...`.

Entries are Markdown files named by date:

```
$DIARY_DIR/2026/10/2026-10-07.md
```

A new entry starts with a `# 2026-10-07 (Wed)` heading. If you quit without
typing anything, no file is written.

### From the shell

| Command            | Opens                    |
| ------------------ | ------------------------ |
| `diary`            | today's entry            |
| `diary -1`         | yesterday's entry        |
| `diary 2026-10-07` | the entry for that date  |

### In Vim

The leader key is Space.

| Command               | Key          | Action                                                |
| --------------------- | ------------ | ----------------------------------------------------- |
| `:Diary [arg]`        | `<Space>dd`  | open today's entry (`arg` works like `diary`)         |
|                       | `<Space>dy`  | open yesterday's entry                                |
| `:DiaryPrev`          | `<Space>dp`  | previous existing entry                               |
| `:DiaryNext`          | `<Space>dn`  | next existing entry                                   |
| `:DiaryStamp`         | `<Space>dt`  | append a `## HH:MM` heading and start typing under it |
| `:DiaryIndex`         | `<Space>di`  | list all entries, newest first; `Enter` opens one, `q` closes the list |
| `:DiaryGrep {pattern}`| `<Space>dg`  | search all entries; results go to the quickfix list   |

Inside the diary directory, Markdown buffers:

- save automatically when you leave Insert mode, change text, or switch away
- wrap long lines at word boundaries, and `j` / `k` move by screen line
- turn on spell checking (English only; CJK text is not marked) when Vim has
  the English spell files
