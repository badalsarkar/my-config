vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 30

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.keymap.set("n", "<Esc>", "<C-w>p", { buffer = true, desc = "Focus previous window" })
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
