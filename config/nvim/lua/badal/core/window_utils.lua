-- Small helpers shared by the floating-window pickers
-- (see file_search.lua and grep_search.lua).

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

return M
