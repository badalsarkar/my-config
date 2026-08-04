-- Shared plumbing for the floating-window pickers (file_search.lua,
-- grep_search.lua, recent_files.lua): a two-float layout (input on top,
-- results below) with common navigation and live filtering.

local M = {}

-- Returns a function that closes all given windows (skips already-closed ones).
function M.make_closer(wins)
  return function()
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  end
end

-- Find the best window to open a file in: prefer the caller's window,
-- but skip netrw, the picker's own floats, and any other floating window.
-- Falls back to any normal window, or nil if there is none.
function M.find_target_win(caller_win, exclude)
  exclude = exclude or {}

  local function is_usable(win)
    if not vim.api.nvim_win_is_valid(win) then return false end
    for _, ex in ipairs(exclude) do
      if win == ex then return false end
    end
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

-- Case-insensitive substring filter over a list of strings.
function M.filter_substring(items, query)
  if query == "" then return vim.list_slice(items) end
  local q = query:lower()
  local result = {}
  for _, item in ipairs(items) do
    if item:lower():find(q, 1, true) then
      table.insert(result, item)
    end
  end
  return result
end

-- Close the picker and open `path` in the best available window (see
-- find_target_win above), optionally placing the cursor at a 1-based
-- lnum/col.
function M.open_file(picker, path, lnum, col)
  picker.close()
  -- Schedule so the picker's windows finish closing before the buffer opens
  vim.schedule(function()
    local target = picker.target_win()
    if target then vim.api.nvim_set_current_win(target) end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    if lnum then
      pcall(vim.api.nvim_win_set_cursor, 0, { lnum, (col or 1) - 1 })
      vim.cmd("normal! zz")
    end
    vim.cmd("stopinsert")
  end)
end

-- Open a two-float picker (input window + results window) and wire up the
-- shared navigation:
--   Type          - live filter (calls opts.on_query on every change)
--   <CR>          - choose the top result (input) or the highlighted one
--                   (results); calls opts.on_select(idx, picker)
--   <Down>/<Tab>  - move focus from input to results
--   <Up>/<Tab>    - move focus from results back to input
--   <Esc>         - close (calls opts.on_close, if given, then the floats)
--
-- opts:
--   title          - input window title, e.g. " Find Files "
--   results_title  - results window title (default " Results ")
--   list_height    - results window height in rows
--   width_frac     - width as a fraction of columns (default 0.7)
--   initial_query  - text to seed the input with (default "")
--   wrap           - whether the results window wraps (default true)
--   on_query(query, picker) - required; must end by calling picker.set_lines
--   on_select(idx, picker)  - required; idx is 1-based into the last
--                             on_query's results
--   on_close()              - optional; called once, before the floats close
--
-- Returns the picker: { iwin, rwin, ibuf, rbuf, caller_win,
--                        set_lines(lines), close(), target_win() }
function M.open_picker(opts)
  local caller_win = vim.api.nvim_get_current_win()

  local width       = math.floor(vim.o.columns * (opts.width_frac or 0.7))
  local list_height = opts.list_height or math.floor(vim.o.lines * 0.5)
  local start_row   = math.floor((vim.o.lines - list_height - 6) / 2)
  local start_col   = math.floor((vim.o.columns - width) / 2)

  local ibuf = vim.api.nvim_create_buf(false, true)
  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative = "editor",
    width = width, height = 1,
    row = start_row, col = start_col,
    style = "minimal", border = "rounded",
    title = opts.title, title_pos = "center",
  })
  vim.wo[iwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  -- start_row + 3 = input row + 1 (input height) + 2 (border lines)
  local rbuf = vim.api.nvim_create_buf(false, true)
  local rwin = vim.api.nvim_open_win(rbuf, false, {
    relative = "editor",
    width = width, height = list_height,
    row = start_row + 3, col = start_col,
    style = "minimal", border = "rounded",
    title = opts.results_title or " Results ", title_pos = "center",
  })
  vim.wo[rwin].cursorline = true
  if opts.wrap == false then vim.wo[rwin].wrap = false end
  vim.wo[rwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  local safe_close = M.make_closer({ iwin, rwin })
  local item_count = 0

  local picker = { iwin = iwin, rwin = rwin, ibuf = ibuf, rbuf = rbuf, caller_win = caller_win }

  function picker.set_lines(lines)
    item_count = #lines
    if not vim.api.nvim_buf_is_valid(rbuf) then return end
    vim.bo[rbuf].modifiable = true
    vim.api.nvim_buf_set_lines(rbuf, 0, -1, false, lines)
    vim.bo[rbuf].modifiable = false
    if item_count > 0 and vim.api.nvim_win_is_valid(rwin) then
      vim.api.nvim_win_set_cursor(rwin, { 1, 0 })
    end
  end

  function picker.target_win()
    return M.find_target_win(caller_win, { iwin, rwin })
  end

  function picker.close()
    if opts.on_close then opts.on_close() end
    safe_close()
  end

  -- ── Input window keymaps ──────────────────────────────────────────────
  -- Mapped in normal mode too, so the picker still responds if you leave
  -- insert mode in the prompt (e.g. via the `jj` mapping).

  local function imap(mode, key, fn)
    vim.keymap.set(mode, key, fn, { buffer = ibuf, noremap = true })
  end

  imap({ "i", "n" }, "<Esc>", picker.close)
  imap({ "i", "n" }, "<CR>", function() opts.on_select(1, picker) end)

  local function focus_results()
    vim.cmd("stopinsert")
    if item_count > 0 then
      vim.api.nvim_set_current_win(rwin)
    end
  end
  imap({ "i", "n" }, "<Down>", focus_results)
  imap({ "i", "n" }, "<Tab>",  focus_results)

  -- ── Results window keymaps ────────────────────────────────────────────

  local function rmap(key, fn)
    vim.keymap.set("n", key, fn, { buffer = rbuf, noremap = true })
  end

  rmap("<CR>", function()
    opts.on_select(vim.api.nvim_win_get_cursor(rwin)[1], picker)
  end)
  rmap("<Esc>", picker.close)

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
      opts.on_query(q, picker)
    end,
  })

  local initial_query = opts.initial_query or ""
  if initial_query ~= "" then
    vim.api.nvim_buf_set_lines(ibuf, 0, -1, false, { initial_query })
  end
  vim.cmd("startinsert!")
  opts.on_query(initial_query, picker)

  return picker
end

return M
