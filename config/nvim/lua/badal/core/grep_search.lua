-- Interactive project-wide string search using ripgrep (no plugins required).
-- See window_utils.lua for the shared picker layout and navigation.
--
-- Searches every file under nvim's current working directory and updates as
-- you type. Space-separated words are ANDed together: "todo parser" shows
-- only lines containing both. Matches are literal text, not regex, so
-- `foo(bar)` searches for exactly that.

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

  -- current_matches: the entries currently listed in the results window
  local current_matches = {}
  -- Bumped on every keystroke so results from a stale rg job are discarded
  local generation = 0
  -- Bumped on every keystroke so a superseded debounce timer does nothing
  local search_seq = 0
  local job_id = nil

  -- Highlight the first term inside the results so matches are easy to spot
  local function highlight_term(picker, term)
    if not vim.api.nvim_win_is_valid(picker.rwin) then return end
    vim.api.nvim_win_call(picker.rwin, function()
      vim.fn.clearmatches()
      if term and term ~= "" then
        -- \V = very nomagic, so the term is treated literally
        vim.fn.matchadd("IncSearch", "\\c\\V" .. vim.fn.escape(term, "\\"))
      end
    end)
  end

  local function render(picker, matches, term)
    current_matches = matches
    if #matches == 0 then
      picker.set_lines({ "  (no matches)" })
    else
      local display = {}
      for _, m in ipairs(matches) do
        table.insert(display, m.display)
      end
      picker.set_lines(display)
    end
    highlight_term(picker, term)
  end

  local function run_search(query, picker)
    generation = generation + 1
    local gen = generation

    if job_id then
      vim.fn.jobstop(job_id)
      job_id = nil
    end

    local terms = split_terms(query)
    if #terms == 0 then
      current_matches = {}
      picker.set_lines({ "  Type to search all files under " .. vim.fn.getcwd() })
      highlight_term(picker, nil)
      return
    end

    job_id = vim.fn.jobstart({ "sh", "-c", build_command(terms) }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if gen ~= generation or not data then return end
        render(picker, parse_matches(data), terms[1])
      end,
    })
  end

  -- Debounce so a fast typist doesn't spawn an rg process per keystroke:
  -- each keystroke invalidates the previous pending search.
  local function schedule_search(query, picker)
    search_seq = search_seq + 1
    local seq = search_seq
    vim.defer_fn(function()
      if seq ~= search_seq then return end  -- superseded by a later keystroke
      if vim.api.nvim_buf_is_valid(picker.ibuf) then run_search(query, picker) end
    end, DEBOUNCE_MS)
  end

  wu.open_picker({
    title = " Search in Files ",
    results_title = " Matches ",
    width_frac = 0.8,
    list_height = math.max(5, math.floor(vim.o.lines * 0.4)),
    wrap = false,
    initial_query = initial_query,
    on_query = schedule_search,
    on_select = function(idx, picker)
      local m = current_matches[idx]
      if m then wu.open_file(picker, m.file, m.lnum, m.col) end
    end,
    on_close = function()
      generation = generation + 1  -- invalidate any in-flight job
      search_seq = search_seq + 1  -- invalidate any pending debounce
      if job_id then
        vim.fn.jobstop(job_id)
        job_id = nil
      end
    end,
  })
end

return M
