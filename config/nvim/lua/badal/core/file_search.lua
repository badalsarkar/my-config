-- Interactive file finder using floating windows (no plugins required).
-- See window_utils.lua for the shared picker layout and navigation.

local wu = require("badal.core.window_utils")

local M = {}

-- Collect files using fd (respects .gitignore) or fall back to find.
local function collect_files()
  if vim.fn.executable("fd") == 1 then
    return vim.fn.systemlist("fd --type f --hidden --follow --exclude .git")
  else
    return vim.fn.systemlist("find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*'")
  end
end

function M.find_files()
  local all_files = collect_files()
  if #all_files == 0 then
    vim.notify("No files found", vim.log.levels.WARN)
    return
  end

  local list_height = math.min(15, #all_files, math.floor(vim.o.lines * 0.5))
  local current_files = {}

  wu.open_picker({
    title = " Find Files ",
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
