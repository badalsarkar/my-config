-- Recently opened files picker (MRU), sourced from this session's buffer
-- visits (see mru.lua). See window_utils.lua for the shared picker layout
-- and navigation.
--
-- mru.get() is already ordered most-recently-used first, so the list is
-- shown as-is, minus files outside cwd, files that no longer exist, and the
-- current buffer.

local wu = require("badal.core.window_utils")
local mru = require("badal.core.mru")

local M = {}

-- Session-visited files that still exist on disk under the current working
-- directory, skipping the file already open in the calling buffer. Paths
-- are shown relative to cwd.
local function collect_recent(skip)
  local cwd = vim.fn.getcwd()
  local prefix = cwd .. "/"
  local files = {}
  for _, f in ipairs(mru.get()) do
    if f ~= skip and f:sub(1, #prefix) == prefix and vim.fn.filereadable(f) == 1 then
      table.insert(files, vim.fn.fnamemodify(f, ":."))
    end
  end
  return files
end

function M.find_recent()
  local current_file = vim.api.nvim_buf_get_name(0)
  local all_files = collect_recent(current_file)
  if #all_files == 0 then
    vim.notify("No recent files", vim.log.levels.WARN)
    return
  end

  local list_height = math.min(15, #all_files, math.floor(vim.o.lines * 0.5))
  local current_files = {}

  wu.open_picker({
    title = " Recent Files ",
    list_height = list_height,
    on_query = function(query, picker)
      current_files = wu.filter_substring(all_files, query)
      picker.set_lines(current_files)
    end,
    on_select = function(idx, picker)
      local f = current_files[idx]
      if f then wu.open_file(picker, f) end
    end,
  })
end

return M
