-- Ctrl+hjkl moves between nvim splits and, at the edge of the split layout,
-- carries on into the surrounding tmux panes.
--
-- This is the nvim half of the contract .tmux.conf already assumes: its is_vim
-- check forwards Ctrl+hjkl into nvim whenever nvim owns the pane, so without
-- these mappings the keys are simply swallowed. Plugin-free, because the whole
-- protocol is "try wincmd; if the window did not change we were at the edge, so
-- ask tmux to move instead".

local M = {}

-- wincmd direction -> tmux select-pane flag
local tmux_flag = { h = "L", j = "D", k = "U", l = "R" }

function M.navigate(dir)
  local from = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)

  -- the window changed, so the move stayed inside nvim and we are done
  if vim.api.nvim_get_current_win() ~= from then
    return
  end

  -- at the edge: hand the movement off to tmux, if we are inside it at all
  if vim.env.TMUX then
    vim.fn.system({ "tmux", "select-pane", "-" .. tmux_flag[dir] })
  end
end

return M
