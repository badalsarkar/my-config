-- Session-local most-recently-used file tracker.
--
-- `vim.v.oldfiles` is only loaded once, from the shada file, at startup --
-- it never updates during a running session (see :help v:oldfiles). So it
-- can't tell you about files opened earlier *this* session, whether or not
-- they were edited. This module fills that gap by watching BufEnter and
-- keeping its own move-to-front list, live.

local M = {}

-- Most-recent-first list of absolute file paths visited this session.
local recent = {}

local function record(path)
  if path == "" then return end
  for i, p in ipairs(recent) do
    if p == path then
      table.remove(recent, i)
      break
    end
  end
  table.insert(recent, 1, path)
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    -- buftype ~= "" covers netrw, terminal, quickfix, and the picker floats
    -- (all scratch/special buffers) -- only track real file buffers.
    if vim.bo[args.buf].buftype ~= "" then return end
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name ~= "" then record(vim.fn.fnamemodify(name, ":p")) end
  end,
})

-- Most-recent-first list of absolute paths visited this session.
function M.get()
  return recent
end

return M
