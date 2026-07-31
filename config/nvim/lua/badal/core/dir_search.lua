-- Interactive directory finder using floating windows (no plugins required).
--
-- Same two-float layout and navigation as file_search.lua, but the source
-- list is directories (including nested ones), and selecting an entry
-- reveals that directory in netrw instead of opening a buffer.
--
-- Layout:
--   ┌─ Find Directory ┐   <- input window: user types here to filter
--   └──────────────────┘
--   ┌─ Results ────────┐   <- results window: shows matching directories
--   │ ./foo/bar        │
--   └──────────────────┘
--
-- Navigation:
--   Type          - filter results live (case-insensitive substring match)
--   <CR>          - reveal first result (from input) or highlighted result (from list)
--   <Down>/<Tab>  - move focus from input to results list
--   <Up>/<Tab>    - move focus from results back to input
--   <Esc>         - close without revealing anything

local wu = require("badal.core.window_utils")

local M = {}

-- Collect directories using fd (respects .gitignore) or fall back to find.
local function collect_dirs()
  if vim.fn.executable("fd") == 1 then
    return vim.fn.systemlist("fd --type d --hidden --follow --exclude .git")
  else
    return vim.fn.systemlist(
      "find . -mindepth 1 -type d -not -path '*/.git/*' -not -path '*/node_modules/*'"
    )
  end
end

-- Filter all_dirs by a case-insensitive substring query.
local function filter_dirs(all_dirs, query)
  if query == "" then return vim.list_slice(all_dirs) end
  local q = query:lower()
  local result = {}
  for _, d in ipairs(all_dirs) do
    if d:lower():find(q, 1, true) then
      table.insert(result, d)
    end
  end
  return result
end

function M.find_dirs()
  local all_dirs = collect_dirs()
  if #all_dirs == 0 then
    vim.notify("No directories found", vim.log.levels.WARN)
    return
  end

  -- Compute floating window dimensions relative to editor size
  local width       = math.floor(vim.o.columns * 0.7)
  local list_height = math.min(15, #all_dirs, math.floor(vim.o.lines * 0.5))
  local start_row   = math.floor((vim.o.lines - list_height - 6) / 2)
  local start_col   = math.floor((vim.o.columns - width) / 2)

  -- Input window: single-line prompt where the user types their query
  local ibuf = vim.api.nvim_create_buf(false, true)
  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative = "editor",
    width = width, height = 1,
    row = start_row, col = start_col,
    style = "minimal", border = "rounded",
    title = " Find Directory ", title_pos = "center",
  })
  vim.wo[iwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  -- Results window: displays the filtered directory list below the input.
  -- start_row + 3 = input row + 1 (input height) + 2 (border lines)
  local rbuf = vim.api.nvim_create_buf(false, true)
  local rwin = vim.api.nvim_open_win(rbuf, false, {
    relative = "editor",
    width = width, height = list_height,
    row = start_row + 3, col = start_col,
    style = "minimal", border = "rounded",
    title = " Results ", title_pos = "center",
  })
  vim.wo[rwin].cursorline = true
  vim.wo[rwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  local safe_close = wu.make_closer({ iwin, rwin })

  -- current_dirs: the filtered subset currently shown in rwin
  local current_dirs = {}

  local function refresh_results(query)
    current_dirs = filter_dirs(all_dirs, query)
    vim.bo[rbuf].modifiable = true
    vim.api.nvim_buf_set_lines(rbuf, 0, -1, false, current_dirs)
    vim.bo[rbuf].modifiable = false
    if #current_dirs > 0 and vim.api.nvim_win_is_valid(rwin) then
      vim.api.nvim_win_set_cursor(rwin, { 1, 0 })
    end
  end

  refresh_results("")
  vim.cmd("startinsert")

  local function select_dir(idx)
    local d = current_dirs[idx or 1]
    if d then
      -- <CR> is usually pressed from insert mode (typing in the prompt); without
      -- this, Neovim stays in insert mode after the floats close, and the next
      -- keystroke gets typed into whatever buffer has focus. If that's netrw
      -- (nomodifiable by design), every subsequent keypress throws E21.
      vim.cmd("stopinsert")
      safe_close()
      -- Schedule so the floats finish closing before netrw takes over the window
      vim.schedule(function()
        require("badal.core.file_explorer").reveal_dir(d)
      end)
    end
  end

  -- ── Input window keymaps ──────────────────────────────────────────────
  -- Bound in normal mode too: the global `jj` -> <Esc> mapping can drop the
  -- prompt out of insert mode, and insert-only bindings would leave it inert.

  local function imap(mode, key, fn)
    vim.keymap.set(mode, key, fn, { buffer = ibuf, noremap = true })
  end

  imap({ "i", "n" }, "<Esc>", safe_close)

  -- <CR> reveals the top result without moving to the results window
  imap({ "i", "n" }, "<CR>", function() select_dir(1) end)

  -- <Down>/<Tab> shifts focus to the results list
  local function focus_results()
    vim.cmd("stopinsert")
    if #current_dirs > 0 then
      vim.api.nvim_set_current_win(rwin)
    end
  end
  imap({ "i", "n" }, "<Down>", focus_results)
  imap({ "i", "n" }, "<Tab>",  focus_results)

  -- ── Results window keymaps ────────────────────────────────────────────

  local function rmap(key, fn)
    vim.keymap.set("n", key, fn, { buffer = rbuf, noremap = true })
  end

  -- <CR> reveals the highlighted entry
  rmap("<CR>", function()
    select_dir(vim.api.nvim_win_get_cursor(rwin)[1])
  end)

  rmap("<Esc>", safe_close)

  -- <Tab> always returns to input; <Up> does too when at the first line
  local function focus_input()
    vim.api.nvim_set_current_win(iwin)
    vim.cmd("startinsert!")
  end
  rmap("<Tab>", focus_input)
  rmap("<Up>", function()
    local cursor_row = vim.api.nvim_win_get_cursor(rwin)[1]
    if cursor_row == 1 then
      focus_input()
    else
      vim.api.nvim_win_set_cursor(rwin, { cursor_row - 1, 0 })
    end
  end)

  -- ── Live filtering ────────────────────────────────────────────────────

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = ibuf,
    callback = function()
      local q = vim.api.nvim_buf_get_lines(ibuf, 0, 1, false)[1] or ""
      refresh_results(q)
    end,
  })
end

return M
