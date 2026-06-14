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
  end,
})

vim.keymap.set("n", "<leader>1", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "netrw" then
      if vim.api.nvim_get_current_win() == win then
        vim.cmd("Lexplore")
      else
        vim.api.nvim_set_current_win(win)
      end
      return
    end
  end
  vim.cmd("Lexplore")
end, { desc = "Toggle or focus netrw file explorer" })
