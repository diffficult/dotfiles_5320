# Prezto Modules Map

This file expands on the module list from [README.md](./README.md) without
leaving the `prezto_runcoms` directory.

## Module roots

There are three module roots in this setup:

| Type | Location | Purpose |
| --- | --- | --- |
| Core Prezto | `~/.zprezto/modules` | Built-in Prezto modules. |
| Prezto contrib | `~/.zprezto/contrib` | Community-maintained extras. |
| Custom local modules | `~/.config/zsh/modules` | Local modules and symlinked external projects. |

## Custom module directory

Current contents of `~/.config/zsh/modules`:

| Module | Location | Notes |
| --- | --- | --- |
| `aichat` | `~/.config/zsh/modules/aichat` | Local custom module. |
| `ask-zsh` | `~/.config/zsh/modules/ask-zsh -> /home/poole/dev/mygits/ask-zsh` | Symlink to local external project. |
| `fabric` | `~/.config/zsh/modules/fabric -> /home/poole/dev/mygits/fabric-zsh` | Symlink to local external project. |
| `fzf` | `~/.config/zsh/modules/fzf` | Custom Prezto-compatible FZF integration. |
| `fzf-alias` | `~/.config/zsh/modules/fzf-alias` | Alias picker widget. |
| `zsh-abbr` | `~/.config/zsh/modules/zsh-abbr` | Abbreviation expansion system. |

## Loaded modules by source

### Core Prezto modules

| Module | Main role |
| --- | --- |
| `environment` | Base shell environment defaults. |
| `terminal` | Terminal title and terminal-specific behavior. |
| `editor` | Keybinding mode and editor behavior. |
| `rsync` | Rsync helpers and completion support. |
| `history` | History file and history behavior. |
| `directory` | Directory stack helpers and directory aliases. |
| `spectrum` | Color helpers. |
| `utility` | General aliases and shell utilities. |
| `ssh` | SSH helpers, identities, completions. |
| `git` | Git aliases, status helpers, completions. |
| `completion` | Completion system and `compinit`. |
| `docker` | Docker and docker-compose aliases. |
| `command-not-found` | Suggest packages when commands are missing. |
| `syntax-highlighting` | Real-time syntax highlighting as you type. |
| `history-substring-search` | Filter history using the current command prefix. |
| `autosuggestions` | Inline gray suggestions from history/completion. |
| `prompt` | Prompt framework and selected theme. |

### Prezto contrib modules

| Module | Main role |
| --- | --- |
| `contrib-prompt` | Additional prompt themes and prompt integrations. |
| `zoxide` | Smarter directory jumping powered by `zoxide`. |

### Custom local modules

| Module | Main role |
| --- | --- |
| `zsh-abbr` | Expands abbreviations on `Space` or `Enter`. |
| `fzf` | Enables FZF shell bindings and fuzzy completion support. |
| `fzf-alias` | Binds `Alt+A` to search aliases with FZF. |
| `fabric` | Fabric-related shell integration. |
| `ask-zsh` | AI helper that generates commands into the prompt for review. |
| `aichat` | Additional AI shell tooling. |

## Current prompt and behavior choices

These choices are currently configured in `zpreztorc` and shape how the modules behave:

| Area | Current setting |
| --- | --- |
| Editor mode | `emacs` key bindings |
| Prompt theme | `pure` |
| History size | `10000` entries |
| FZF key bindings | enabled |
| FZF completion | disabled in the module; custom setup lives in `zshrc` |
| Autosuggestions | enabled |
| Syntax highlighters | `main`, `brackets`, `pattern`, `line` |

## Most useful modules in practice

### Navigation

| Module | Useful things |
| --- | --- |
| `directory` | `d`, `1..9` |
| `zoxide` | Smarter directory jumping |
| `fzf` | `Ctrl+T`, `Ctrl+R`, `Alt+C` |
| `history-substring-search` | `Up`, `Down`, `Ctrl+P`, `Ctrl+N` |

### Command writing

| Module | Useful things |
| --- | --- |
| `autosuggestions` | Accept suggestions with `Right` or `End` |
| `zsh-abbr` | Expand abbreviations with `Space` or `Enter` |
| `syntax-highlighting` | Visual feedback while typing |
| `fzf-alias` | `Alt+A` alias picker |

### Tool-specific helpers

| Module | Useful things |
| --- | --- |
| `git` | `g`, `gb`, `gc`, `gcm`, `gco`, `gd`, `gf` |
| `docker` | `dk`, `dkps`, `dkl`, `dki`, `dkc` |
| `ssh` | SSH identities and completion helpers |
| `command-not-found` | Package suggestions for missing commands |

### AI and assistant tooling

| Module | Useful things |
| --- | --- |
| `ask-zsh` | `ask-zsh "..."` to draft a command into the prompt |
| `fabric` | Fabric shell integration |
| `aichat` | AI chat-style shell tooling |
| `navi` in `zshrc` | `Ctrl+G` cheatsheet launcher |

## Where to edit what

| If you want to change... | Edit... |
| --- | --- |
| Loaded modules | `zpreztorc` |
| Prompt theme and module styles | `zpreztorc` |
| Keybinding-driven integrations like Navi/FZF helpers | `zshrc` |
| PATH and login environment | `zprofile` |
| Module source code under dotfiles control | `~/.config/zsh/modules/*` |

## Quick inspection commands

```zsh
# Show loaded aliases
alias | less

# Show current key bindings
bindkey | less

# Show all keymaps
bindkey-all | less

# Show abbreviation help
abbr help
```
