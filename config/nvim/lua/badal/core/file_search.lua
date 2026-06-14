-- Interactive file finder using floating windows (no plugins required).
--
-- Layout:
--   ┌─ Find Files ───┐   <- input window: user types here to filter
--   └────────────────┘
--   ┌─ Results ──────┐   <- results window: shows matching files
--   │ ./foo.lua      │
--   │ ./bar.txt      │
--   └────────────────┘
--
-- Navigation:
--   Type          - filter results live (case-insensitive substring match)
--   <CR>          - open first result (from input) or highlighted result (from list)
--   <Down>/<Tab>  - move focus from input to results list
--   <Up>/<Tab>    - move focus from results back to input
--   <Esc>         - close without opening anything

local M = {}

-- Collect files using fd (respects .gitignore) or fall back to find.
local function collect_files()
  if vim.fn.executable("fd") == 1 then
    return vim.fn.systemlist("fd --type f --hidden --follow --exclude .git")
  else
    return vim.fn.systemlist("find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*'")
  end
end

-- Filter all_files by a case-insensitive substring query.
local function filter_files(all_files, query)
  if query == "" then return vim.list_slice(all_files) end
  local q = query:lower()
  local result = {}
  for _, f in ipairs(all_files) do
    if f:lower():find(q, 1, true) then
      table.insert(result, f)
    end
  end
  return result
end

-- Returns a function that closes all given windows (skips already-closed ones).
local function make_closer(wins)
  return function()
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  end
end

-- Find the best window to open a file in: prefer the caller's window,
-- but skip netrw and floating windows. Falls back to any normal window.
local function find_target_win(caller_win, iwin, rwin)
  local function is_usable(win)
    if not vim.api.nvim_win_is_valid(win) then return false end
    if win == iwin or win == rwin then return false end
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= "" then return false end  -- floating
    local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    return ft ~= "netrw"
  end

  if is_usable(caller_win) then return caller_win end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_usable(win) then return win end
  end

  return nil  -- no suitable window; edit will open wherever focus lands
end

function M.find_files()
  local all_files = collect_files()
  if #all_files == 0 then
    vim.notify("No files found", vim.log.levels.WARN)
    return
  end

  -- Remember the active window so we can open the file there, not in netrw
  local caller_win = vim.api.nvim_get_current_win()

  -- Compute floating window dimensions relative to editor size
  local width       = math.floor(vim.o.columns * 0.7)
  local list_height = math.min(15, #all_files, math.floor(vim.o.lines * 0.5))
  local start_row   = math.floor((vim.o.lines - list_height - 6) / 2)
  local start_col   = math.floor((vim.o.columns - width) / 2)

  -- Input window: single-line prompt where the user types their query
  local ibuf = vim.api.nvim_create_buf(false, true)
  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative = "editor",
    width = width, height = 1,
    row = start_row, col = start_col,
    style = "minimal", border = "rounded",
    title = " Find Files ", title_pos = "center",
  })
  vim.wo[iwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  -- Results window: displays the filtered file list below the input.
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

  local safe_close = make_closer({ iwin, rwin })

  -- current_files: the filtered subset currently shown in rwin
  local current_files = {}

  local function refresh_results(query)
    current_files = filter_files(all_files, query)
    vim.bo[rbuf].modifiable = true
    vim.api.nvim_buf_set_lines(rbuf, 0, -1, false, current_files)
    vim.bo[rbuf].modifiable = false
    if #current_files > 0 and vim.api.nvim_win_is_valid(rwin) then
      vim.api.nvim_win_set_cursor(rwin, { 1, 0 })
    end
  end

  refresh_results("")
  vim.cmd("startinsert")

  local function open_file(idx)
    local f = current_files[idx or 1]
    if f then
      safe_close()
      -- Schedule so windows finish closing before the buffer is opened
      vim.schedule(function()
        local target = find_target_win(caller_win, iwin, rwin)
        if target then vim.api.nvim_set_current_win(target) end
        vim.cmd("edit " .. vim.fn.fnameescape(f))
        vim.cmd("stopinsert")
      end)
    end
  end

  -- ── Input window keymaps ──────────────────────────────────────────────

  local function imap(mode, key, fn)
    vim.keymap.set(mode, key, fn, { buffer = ibuf, noremap = true })
  end

  imap({ "i", "n" }, "<Esc>", safe_close)

  -- <CR> opens the top result without moving to the results window
  imap("i", "<CR>", function() open_file(1) end)

  -- <Down>/<Tab> shifts focus to the results list
  local function focus_results()
    vim.cmd("stopinsert")
    vim.api.nvim_set_current_win(rwin)
  end
  imap("i", "<Down>", focus_results)
  imap("i", "<Tab>",  focus_results)

  -- ── Results window keymaps ────────────────────────────────────────────

  local function rmap(key, fn)
    vim.keymap.set("n", key, fn, { buffer = rbuf, noremap = true })
  end

  -- <CR> opens the highlighted entry
  rmap("<CR>", function()
    open_file(vim.api.nvim_win_get_cursor(rwin)[1])
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
