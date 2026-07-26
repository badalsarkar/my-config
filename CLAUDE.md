# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal dotfiles and system configuration for a Fedora Linux laptop. There is no build system or test suite — changes take effect by symlinking config files into place or reloading the relevant tool.

## Deploying Changes

Symlinks are set up via `scripts/do-symlink.sh`, which wires the three main configs into `~/`:

```sh
ln -sf ~/badal/my-config/config/zsh/.zshrc ~/
ln -sf ~/badal/my-config/config/vim/.vimrc ~/
ln -sf ~/badal/my-config/config/tmux/.tmux.conf ~/
```

Neovim and other configs under `config/` must be symlinked to their expected locations manually (e.g. `~/.config/nvim` → `config/nvim`).

**Reload shortcuts:**
- tmux: `prefix + R` sources `~/.tmux.conf`
- zsh: `src` alias (`source ~/.zshrc`)
- i3: `$mod+Shift+c` reloads; `$mod+Shift+r` restarts
- sway: `$mod+Shift+c` reloads

## Repository Structure

```
aliases/zsh/          # zsh aliases sourced by .zshrc
  base-aliases        # nav, editor shortcuts, common aliases
  git-aliases         # git shortcuts + gcp() function
config/
  nvim/               # Neovim config (Lua)
  tmux/               # tmux config + layout scripts
  zsh/.zshrc          # zsh entry point; sources aliases, sets BADAL_HOME
  vim/.vimrc
  alacritty/
  i3wm/
  sway/
  waybar/
scripts/              # one-shot install scripts (Fedora-targeted)
```

## Neovim Config Architecture

Entry point: `config/nvim/init.lua` → `require("badal.core")`

- `lua/badal/core/init.lua` — loads `options`, `keymaps`, `file_explorer`, `file_search`
- `lua/badal/core/options.lua` — vim options (tabs, search, UI)
- `lua/badal/core/keymaps.lua` — leader key (`<Space>`), splits, tabs, markdown preview
- `lua/badal/core/file_explorer.lua` — netrw config; `<leader>1` toggles/focuses it; `a` in netrw creates files/dirs via popup
- `lua/badal/core/file_search.lua` — plugin-free file finder; `<leader>ff` opens floating prompt with live filtering; uses `fd` if available, falls back to `find`
- `lua/badal/lazy.lua` — bootstraps lazy.nvim and loads plugins from `badal.plugins` and `badal.plugins.lsp`

Plugin specs live under `lua/badal/plugins/` (not tracked in this repo — managed by lazy.nvim at runtime).

## tmux Config Notes

- Layout scripts: `prefix+N` (laptop), `prefix+W` (widescreen) run `config/tmux/layouts/laptop.sh` and `widescreen.sh`
- Last-window toggle (`prefix+L`) uses `config/tmux/last-pane-track.sh` via a `pane-focus-in` hook
- Paths in `.tmux.conf` are hardcoded to `~/Documents/badal/my-config/` — update these if the repo moves
- Uses TPM for plugins: tmux-resurrect, tmux-continuum (auto-restore on), tmux-yank
- vim-tmux-navigator: `Ctrl+hjkl` moves between nvim splits and tmux panes without prefix

## zsh / Aliases

`$BADAL_HOME` is set to `$HOME/Documents` in `.zshrc`. Quick navigation aliases: `myconfig`, `myscripts`, `myalias` cd into this repo's subdirs.
