# Prezto Runcoms in `~/.config/zsh`

These runcoms live in:

```text
~/.config/zsh/prezto_runcoms
```

Your home-level dotfiles are symlinked here, so Zsh still loads the usual names:

```text
~/.zshenv    -> ~/.config/zsh/prezto_runcoms/zshenv
~/.zprofile  -> ~/.config/zsh/prezto_runcoms/zprofile
~/.zshrc     -> ~/.config/zsh/prezto_runcoms/zshrc
~/.zpreztorc -> ~/.config/zsh/prezto_runcoms/zpreztorc
~/.zlogin    -> ~/.config/zsh/prezto_runcoms/zlogin
~/.zlogout   -> ~/.config/zsh/prezto_runcoms/zlogout
```

## Quick path

1. Edit shell startup behavior in `zshrc`.
2. Edit Prezto modules and styles in `zpreztorc`.
3. Edit login-time environment and PATH in `zprofile`.
4. Open a new shell, or run `exec zsh`, to test changes.

## Layout

| Path | Purpose |
| --- | --- |
| `zshenv` | Minimal bootstrap. Ensures non-login shells can still inherit `zprofile`. |
| `zprofile` | Login-shell environment: XDG paths, PATH setup, locale, keyboard layout, desktop-related exports. |
| `zshrc` | Interactive shell setup: Prezto init, aliases, helper scripts, FZF, Navi, pay-respects, completions, app integrations. |
| `zpreztorc` | Prezto configuration: module list, prompt theme, completion behavior, history, syntax highlighting, FZF settings. |
| `zlogin` | Commands that run after login shell startup. |
| `zlogout` | Commands that run when a login shell exits. |

## How Prezto Fits Together

The main Prezto repository lives in:

```text
~/.zprezto
```

Startup flow, simplified:

1. `~/.zshenv` loads first.
2. `~/.zprofile` runs for login shells.
3. `~/.zshrc` starts Prezto via `~/.zprezto/init.zsh`.
4. Prezto reads `~/.zpreztorc` to decide which modules to load.
5. Your custom module directory at `~/.config/zsh/modules` is added on top of Prezto's built-in modules and contrib modules.

## Module Sources

Prezto is loading modules from three places:

| Source | Location | Notes |
| --- | --- | --- |
| Core Prezto modules | `~/.zprezto/modules` | Standard Prezto functionality. |
| Prezto contrib modules | `~/.zprezto/contrib` | Extra community modules like `contrib-prompt` and `zoxide`. |
| Custom modules | `~/.config/zsh/modules` | Local overrides and third-party modules outside the Prezto repo. |

Current custom modules directory contents:

```text
~/.config/zsh/modules/
  aichat/
  ask-zsh/   -> /home/poole/dev/mygits/ask-zsh
  fabric/    -> /home/poole/dev/mygits/fabric-zsh
  fzf/
  fzf-alias/
  zsh-abbr/
```

## Loaded Modules

These are the modules currently enabled in `zpreztorc`:

```text
environment
terminal
editor
rsync
history
directory
spectrum
utility
ssh
git
completion
docker
command-not-found
syntax-highlighting
history-substring-search
zsh-abbr
autosuggestions
contrib-prompt
fzf
fzf-alias
zoxide
fabric
ask-zsh
aichat
prompt
```

For a more detailed module map, including where each module comes from and what
it is for, see [MODULES.md](./MODULES.md).

## What Matters Most

| Module | What you get |
| --- | --- |
| `prompt` + `contrib-prompt` | Prompt theme support. Current theme is `pure`. |
| `git` | Large Git alias set such as `g`, `gb`, `gc`, `gco`, `gd`. |
| `docker` | Docker aliases such as `dk`, `dkps`, `dkl`, `dkc`. |
| `directory` | Directory stack helpers like `d` and numeric jumps `1..9`. |
| `completion` | Prezto completion engine and `compinit`. |
| `history-substring-search` | Search history using what is already typed. |
| `autosuggestions` | Gray inline suggestions from history/completion. |
| `fzf` | Fuzzy file/history/directory navigation bindings. |
| `fzf-alias` | Fuzzy alias picker. |
| `zsh-abbr` | Abbreviations that expand as you type. |
| `zoxide` | Smarter directory jumping. |
| `command-not-found` | Package suggestions when a command is missing. |
| `ask-zsh` | AI-assisted terminal helper for generating commands. |
| `fabric` / `aichat` | Extra AI-oriented shell integrations. |

## Cheatsheet

### Navigation and Search

| Shortcut | Action |
| --- | --- |
| `Ctrl+G` | Open `navi` cheatsheets widget. |
| `Ctrl+T` | FZF file picker; inserts selected path into the command line. |
| `Ctrl+R` | FZF history search. |
| `Alt+C` | FZF directory picker and `cd` into the selection. |
| `Alt+A` | Fuzzy alias picker from `fzf-alias`. |
| `Up` / `Down` | History substring search using the text already typed. |
| `Ctrl+P` / `Ctrl+N` | History substring search in emacs keybindings mode. |
| `d` | Show directory stack. |
| `1` to `9` | Jump to previous directories in the stack. |

### Inline Assistance

| Shortcut | Action |
| --- | --- |
| `Right` | Accept current autosuggestion. |
| `End` | Accept current autosuggestion. |
| `Space` | Expand matching `zsh-abbr` abbreviations. |
| `Enter` | Expand and run matching command abbreviations from `zsh-abbr`. |
| `Ctrl+Space` | Skip abbreviation expansion for the current token. |

### Commands Worth Remembering

| Command | Meaning |
| --- | --- |
| `abbr help` | Show `zsh-abbr` help. |
| `alias` | List current aliases. |
| `bindkey` | List current key bindings for the active keymap. |
| `bindkey-all` | List bindings across all keymaps. |
| `ask-zsh "..."` | Ask for a shell command and place it on the prompt for review. |

### Common Alias Families

| Prefix | Tool | Examples |
| --- | --- | --- |
| `g` | Git | `g`, `gb`, `gc`, `gcm`, `gco`, `gd`, `gf` |
| `dk` | Docker | `dk`, `dkps`, `dkl`, `dki`, `dkc` |
| `kb` | Kubernetes | `kb`, `kbg`, `kbd`, `kbl`, `kbcg`, `kbcu` |

## Linking Command

If you ever need to recreate the symlinks from `$HOME`, this is the command that links these runcoms:

```zsh
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.config/zsh/prezto_runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
```

## Sanity Check

After editing these files, validate with:

```zsh
zsh -n ~/.config/zsh/prezto_runcoms/zshrc
```

Then reload the shell:

```zsh
exec zsh
```
