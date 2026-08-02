vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 30

local function input_popup(prompt, callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 50
  local row = math.floor((vim.o.lines - 1) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. prompt .. " ",
    title_pos = "center",
  })

  vim.cmd("startinsert")

  local function close(value)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.schedule(function() callback(value) end)
  end

  vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    vim.cmd("stopinsert")
    close(line)
  end, { buffer = buf, nowait = true })

  for _, key in ipairs({ "<Esc>", "<C-c>" }) do
    vim.keymap.set({ "i", "n" }, key, function()
      vim.cmd("stopinsert")
      close(nil)
    end, { buffer = buf, nowait = true })
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.keymap.set("n", "<Esc>", "<C-w>p", { buffer = true, desc = "Focus previous window" })

    vim.keymap.set("n", "a", function()
      local curdir = vim.b.netrw_curdir
      local netrw_win = vim.api.nvim_get_current_win()

      input_popup("New file/dir (end with / for dir):", function(name)
        if not name or name == "" then
          vim.api.nvim_set_current_win(netrw_win)
          return
        end

        if name:sub(-1) == "/" then
          local dir_path = curdir .. "/" .. name:sub(1, -2)
          vim.fn.mkdir(dir_path, "p")
          vim.api.nvim_set_current_win(netrw_win)
          vim.cmd("e .")
        else
          local file_path = curdir .. "/" .. name
          local f = io.open(file_path, "a")
          if f then f:close() end

          -- find a non-netrw window to open the file in, or create a split
          local target_win = nil
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if win ~= netrw_win then
              target_win = win
              break
            end
          end

          if target_win then
            vim.api.nvim_set_current_win(target_win)
          else
            vim.api.nvim_set_current_win(netrw_win)
            vim.cmd("wincmd l | vsplit")
            target_win = vim.api.nvim_get_current_win()
          end

          vim.cmd("edit " .. vim.fn.fnameescape(file_path))

          -- refresh netrw in background
          vim.api.nvim_set_current_win(netrw_win)
          vim.cmd("e .")
          vim.api.nvim_set_current_win(target_win)
        end
      end)
    end, { buffer = true, desc = "Create new file or directory" })

    vim.keymap.set("n", "<leader>mo", function()
      local fname = vim.fn["netrw#GX"]()
      local path = fname:match("^/") and fname or (vim.b.netrw_curdir .. "/" .. fname)
      vim.fn.jobstart({ "pycharm", "-e", path }, { detach = true })
    end, { buffer = true, desc = "Open file under cursor in pycharm" })
  end,
})

local M = {}

local function find_netrw_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "netrw" then
      return win
    end
  end
  return nil
end

-- Focus the netrw window, opening it if it is not on screen.
local function open_explorer()
  local win = find_netrw_win()
  if win then
    vim.api.nvim_set_current_win(win)
    return win
  end
  vim.cmd("Lexplore")
  return find_netrw_win()
end

vim.keymap.set("n", "<leader>1", function()
  local win = find_netrw_win()
  if win then
    if vim.api.nvim_get_current_win() == win then
      vim.cmd("Lexplore")
    else
      vim.api.nvim_set_current_win(win)
    end
    return
  end
  vim.cmd("Lexplore")
end, { desc = "Toggle or focus netrw file explorer" })

-- netrw's s:treedepthstring: one of these per nesting level in tree list style.
-- (netrw only uses the "│ " variant under a GUI, so terminal nvim always gets "| ".)
local DEPTH = "| "

-- netrw keys w:netrw_treedict by the absolute path of every expanded directory,
-- sometimes with and sometimes without the trailing slash.
local function is_expanded(dir)
  local treedict = vim.w.netrw_treedict or {}
  return treedict[dir] ~= nil or treedict[dir .. "/"] ~= nil
end

-- Move the cursor to the `depth`-nested entry named `name`, searching forward
-- from where the cursor already is. Searching from the parent's line (rather
-- than the top of the buffer) is what keeps same-named files apart: a
-- directory's children are always the first entries of that depth below it.
local function goto_entry(depth, name)
  local pattern = "^\\V" .. DEPTH:rep(depth) .. vim.fn.escape(name, "\\")
  return vim.fn.search(pattern, "W")
end

-- Shared by reveal_current_file and reveal_dir. `path` is an absolute path
-- with no trailing slash; `path_is_dir` says whether the *last* path segment
-- is itself a directory (and should therefore be expanded, not just found).
local function reveal_path(path, path_is_dir)
  if not open_explorer() then
    vim.notify("Could not open netrw", vim.log.levels.ERROR)
    return
  end

  local function root()
    local top = vim.w.netrw_treetop or vim.b.netrw_curdir or vim.fn.getcwd()
    return (top:gsub("/$", ""))
  end

  -- If the path lives outside the tree, re-root the explorer at its directory.
  -- (:edit on a directory does not re-trigger netrw from inside a netrw buffer,
  -- :Explore does.)
  local top = root()
  if path:sub(1, #top + 1) ~= top .. "/" and path ~= top then
    local start_dir = path_is_dir and path or vim.fn.fnamemodify(path, ":h")
    vim.cmd("Explore " .. vim.fn.fnameescape(start_dir))
    top = root()
    if path:sub(1, #top + 1) ~= top .. "/" and path ~= top then
      vim.notify("Could not root netrw at " .. path, vim.log.levels.WARN)
      return
    end
  end

  -- The target directory is exactly what netrw is now rooted at; nothing left
  -- to expand. Leave the cursor where netrw itself puts it (its first entry).
  if path == top then
    return
  end

  local parts = vim.split(path:sub(#top + 2), "/")
  vim.fn.cursor(1, 1)

  for i, part in ipairs(parts) do
    local is_dir = path_is_dir or i < #parts
    if goto_entry(i, is_dir and (part .. "/") or part) == 0 then
      vim.notify("Could not find " .. part .. " in the tree", vim.log.levels.WARN)
      return
    end
    -- <CR> toggles, so only press it on directories that are still collapsed.
    if is_dir and not is_expanded(top .. "/" .. table.concat(parts, "/", 1, i)) then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
    end
  end
end

-- Expand the tree down to the file in the current buffer and put the cursor on it.
function M.reveal_current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype == "netrw" or vim.bo.buftype ~= "" or path == "" then
    vim.notify("No file in this buffer to reveal", vim.log.levels.WARN)
    return
  end

  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("Not a readable file: " .. path, vim.log.levels.WARN)
    return
  end

  reveal_path(path, false)
end

-- Expand the tree down to `path` (a directory, absolute or relative) and
-- expand it too, so its contents are visible.
function M.reveal_dir(path)
  path = (vim.fn.fnamemodify(path, ":p"):gsub("/$", ""))
  if vim.fn.isdirectory(path) ~= 1 then
    vim.notify("Not a directory: " .. path, vim.log.levels.WARN)
    return
  end

  reveal_path(path, true)
end

-- Expand every directory in the tree, however deeply nested. netrw has no
-- native recursive expand, so this repeatedly walks the buffer top-to-bottom
-- rebuilding each entry's absolute path from the depth-prefixed line above it,
-- and presses <CR> on the first still-collapsed directory it finds. A newly
-- expanded directory inserts its children right below, so restarting the walk
-- from the top after each expansion is what reaches them.
--
-- Dotfiles repos are full of symlinks, and a symlink that points back at an
-- ancestor directory makes the *displayed* path grow forever (foo/bar/foo/
-- bar/...) without ever repeating, so dedup by that string never fires.
-- Instead we dedup by the resolved realpath, which a cycle does repeat, and
-- keep a hard cap as a circuit breaker regardless of cause.
local MAX_EXPANSIONS = 2000

-- Directories left collapsed by expand_all: usually huge, rarely worth
-- browsing, and would otherwise dominate the walk. Edit freely.
local SKIP_DIRS = {
  [".git"] = true,
  ["node_modules"] = true,
  [".cache"] = true,
  ["__pycache__"] = true,
  [".venv"] = true,
  ["venv"] = true,
}

function M.expand_all()
  local top = (vim.w.netrw_treetop or vim.b.netrw_curdir or vim.fn.getcwd()):gsub("/$", "")
  local visited = {}
  local count = 0

  while true do
    local stack = {}
    local expanded_one = false

    for lnum = 1, vim.api.nvim_buf_line_count(0) do
      local rest, depth = vim.fn.getline(lnum), 0
      while rest:sub(1, #DEPTH) == DEPTH do
        depth = depth + 1
        rest = rest:sub(#DEPTH + 1)
      end

      if rest:sub(-1) == "/" and rest ~= "./" and rest ~= "../" then
        local name = rest:sub(1, -2)
        stack[depth + 1] = name
        for i = depth + 2, #stack do
          stack[i] = nil
        end

        local path = top .. "/" .. table.concat(stack, "/", 1, depth + 1)
        local real = vim.fn.resolve(path)
        if not SKIP_DIRS[name] and not visited[real] and not is_expanded(path) then
          visited[real] = true
          count = count + 1
          if count > MAX_EXPANSIONS then
            vim.notify("expand_all: stopped after " .. MAX_EXPANSIONS .. " directories (possible symlink cycle?)", vim.log.levels.WARN)
            return
          end
          vim.fn.cursor(lnum, 1)
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "x", false)
          expanded_one = true
          break
        end
      end
    end

    if not expanded_one then
      break
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.keymap.set("n", "zR", M.expand_all, { buffer = true, desc = "Expand all directories in the tree" })
  end,
})

return M
