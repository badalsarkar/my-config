-- Interactive project-wide string search using ripgrep (no plugins required).
--
-- Searches every file under nvim's current working directory and updates as
-- you type. Space-separated words are ANDed together: "todo parser" shows
-- only lines containing both.
--
-- Layout:
--   ┌─ Search in Files ─┐   <- input window: user types here
--   └───────────────────┘
--   ┌─ Matches ─────────┐   <- results window: file:line: matching text
--   │ lua/init.lua:3: … │
--   └───────────────────┘
--
-- Navigation:
--   Type          - re-run the search live (case-insensitive unless you
--                   type an uppercase letter -- ripgrep's smart-case)
--   <CR>          - jump to first match (from input) or highlighted match
--   <Down>/<Tab>  - move focus from input to results list
--   <Up>/<Tab>    - move focus from results back to input
--   <Esc>         - close without jumping anywhere
--
-- Matches are literal text, not regex, so `foo(bar)` searches for exactly that.

local wu = require("badal.core.window_utils")

local M = {}

local MAX_RESULTS = 2000
local DEBOUNCE_MS = 120

-- Split a query into search terms on whitespace.
local function split_terms(query)
  local terms = {}
  for word in query:gmatch("%S+") do
    table.insert(terms, word)
  end
  return terms
end

-- Build a shell pipeline: the first term drives ripgrep, each extra term
-- filters the previous output, so all terms must be present on a line.
-- Note the filters see the whole "file:line:col:text" record, so an extra
-- term may also match against the file path.
--
-- The trailing "." matters: without an explicit path ripgrep reads stdin,
-- and jobstart() hands it a pipe that never closes, so it would hang.
local function build_command(terms)
  local parts = {
    "rg --vimgrep --smart-case --fixed-strings --hidden --glob '!.git' -- "
      .. vim.fn.shellescape(terms[1]) .. " .",
  }
  for i = 2, #terms do
    table.insert(parts, "rg --smart-case --fixed-strings -- " .. vim.fn.shellescape(terms[i]))
  end
  table.insert(parts, "head -n " .. MAX_RESULTS)
  return table.concat(parts, " | ")
end

-- Parse ripgrep --vimgrep output ("path:lnum:col:text") into entries.
local function parse_matches(lines)
  local matches = {}
  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
    if file then
      table.insert(matches, {
        file = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        display = string.format("%s:%s: %s", file, lnum, (text:gsub("^%s+", ""))),
      })
    end
  end
  return matches
end

-- initial_query pre-fills the prompt (used by the word-under-cursor mapping).
function M.grep_files(initial_query)
  if vim.fn.executable("rg") ~= 1 then
    vim.notify("ripgrep (rg) is required for <leader>fs", vim.log.levels.ERROR)
    return
  end

  initial_query = initial_query or ""

  -- Remember the active window so we can open the file there, not in netrw
  local caller_win = vim.api.nvim_get_current_win()

  -- Compute floating window dimensions relative to editor size
  local width       = math.floor(vim.o.columns * 0.8)
  local list_height = math.max(5, math.floor(vim.o.lines * 0.4))
  local start_row   = math.floor((vim.o.lines - list_height - 6) / 2)
  local start_col   = math.floor((vim.o.columns - width) / 2)

  -- Input window: single-line prompt where the user types their query
  local ibuf = vim.api.nvim_create_buf(false, true)
  local iwin = vim.api.nvim_open_win(ibuf, true, {
    relative = "editor",
    width = width, height = 1,
    row = start_row, col = start_col,
    style = "minimal", border = "rounded",
    title = " Search in Files ", title_pos = "center",
  })
  vim.wo[iwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  -- Results window: displays the matches below the input.
  -- start_row + 3 = input row + 1 (input height) + 2 (border lines)
  local rbuf = vim.api.nvim_create_buf(false, true)
  local rwin = vim.api.nvim_open_win(rbuf, false, {
    relative = "editor",
    width = width, height = list_height,
    row = start_row + 3, col = start_col,
    style = "minimal", border = "rounded",
    title = " Matches ", title_pos = "center",
  })
  vim.wo[rwin].cursorline = true
  vim.wo[rwin].wrap = false
  vim.wo[rwin].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"

  local safe_close = wu.make_closer({ iwin, rwin })

  -- current_matches: the entries currently listed in rwin
  local current_matches = {}
  -- Bumped on every keystroke so results from a stale rg job are discarded
  local generation = 0
  -- Bumped on every keystroke so a superseded debounce timer does nothing
  local search_seq = 0
  local job_id = nil

  local function set_lines(lines)
    if not vim.api.nvim_buf_is_valid(rbuf) then return end
    vim.bo[rbuf].modifiable = true
    vim.api.nvim_buf_set_lines(rbuf, 0, -1, false, lines)
    vim.bo[rbuf].modifiable = false
  end

  -- Highlight the first term inside the results so matches are easy to spot
  local function highlight_term(term)
    if not vim.api.nvim_win_is_valid(rwin) then return end
    vim.api.nvim_win_call(rwin, function()
      vim.fn.clearmatches()
      if term and term ~= "" then
        -- \V = very nomagic, so the term is treated literally
        vim.fn.matchadd("IncSearch", "\\c\\V" .. vim.fn.escape(term, "\\"))
      end
    end)
  end

  local function render(matches, term)
    current_matches = matches
    if #matches == 0 then
      set_lines({ "  (no matches)" })
    else
      local display = {}
      for _, m in ipairs(matches) do
        table.insert(display, m.display)
      end
      set_lines(display)
    end
    highlight_term(term)
    if #matches > 0 and vim.api.nvim_win_is_valid(rwin) then
      vim.api.nvim_win_set_cursor(rwin, { 1, 0 })
    end
  end

  local function run_search(query)
    generation = generation + 1
    local gen = generation

    if job_id then
      vim.fn.jobstop(job_id)
      job_id = nil
    end

    local terms = split_terms(query)
    if #terms == 0 then
      render({}, nil)
      set_lines({ "  Type to search all files under " .. vim.fn.getcwd() })
      return
    end

    job_id = vim.fn.jobstart({ "sh", "-c", build_command(terms) }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if gen ~= generation or not data then return end
        render(parse_matches(data), terms[1])
      end,
    })
  end

  -- Debounce so a fast typist doesn't spawn an rg process per keystroke:
  -- each keystroke invalidates the previous pending search.
  local function schedule_search(query)
    search_seq = search_seq + 1
    local seq = search_seq
    vim.defer_fn(function()
      if seq ~= search_seq then return end  -- superseded by a later keystroke
      if vim.api.nvim_buf_is_valid(ibuf) then run_search(query) end
    end, DEBOUNCE_MS)
  end

  local function cleanup()
    generation = generation + 1  -- invalidate any in-flight job
    search_seq = search_seq + 1  -- invalidate any pending debounce
    if job_id then
      vim.fn.jobstop(job_id)
      job_id = nil
    end
    safe_close()
  end

  local function open_match(idx)
    local m = current_matches[idx or 1]
    if not m then return end
    cleanup()
    -- Schedule so windows finish closing before the buffer is opened
    vim.schedule(function()
      local target = wu.find_target_win(caller_win, { iwin, rwin })
      if target then vim.api.nvim_set_current_win(target) end
      vim.cmd("edit " .. vim.fn.fnameescape(m.file))
      pcall(vim.api.nvim_win_set_cursor, 0, { m.lnum, m.col - 1 })
      vim.cmd("normal! zz")
      vim.cmd("stopinsert")
    end)
  end

  -- ── Input window keymaps ──────────────────────────────────────────────

  local function imap(mode, key, fn)
    vim.keymap.set(mode, key, fn, { buffer = ibuf, noremap = true })
  end

  -- Mapped in normal mode too, so the picker still responds if you leave
  -- insert mode in the prompt (e.g. via the `jj` mapping).
  imap({ "i", "n" }, "<Esc>", cleanup)

  -- <CR> jumps to the top match without moving to the results window
  imap({ "i", "n" }, "<CR>", function() open_match(1) end)

  -- <Down>/<Tab> shifts focus to the results list
  local function focus_results()
    vim.cmd("stopinsert")
    if #current_matches > 0 then
      vim.api.nvim_set_current_win(rwin)
    end
  end
  imap({ "i", "n" }, "<Down>", focus_results)
  imap({ "i", "n" }, "<Tab>",  focus_results)

  -- ── Results window keymaps ────────────────────────────────────────────

  local function rmap(key, fn)
    vim.keymap.set("n", key, fn, { buffer = rbuf, noremap = true })
  end

  -- <CR> jumps to the highlighted match
  rmap("<CR>", function()
    open_match(vim.api.nvim_win_get_cursor(rwin)[1])
  end)

  rmap("<Esc>", cleanup)

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

  -- ── Live searching ────────────────────────────────────────────────────

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = ibuf,
    callback = function()
      schedule_search(vim.api.nvim_buf_get_lines(ibuf, 0, 1, false)[1] or "")
    end,
  })

  -- Seed the prompt and show the first batch of results
  vim.api.nvim_buf_set_lines(ibuf, 0, -1, false, { initial_query })
  vim.cmd("startinsert!")
  run_search(initial_query)
end

return M
