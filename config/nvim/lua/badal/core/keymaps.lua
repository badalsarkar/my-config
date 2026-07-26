vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>", {desc = "Exit insert mode"})

keymap.set("n", "<Esc>", ":nohl<CR>", { desc = "Clear search highlights"})

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- tab management
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- file search
keymap.set("n", "<leader>ff", function()
  require("badal.core.file_search").find_files()
end, { desc = "Find files" })

-- markdown preview with glow
keymap.set("n", "<leader>mp", function()
  vim.cmd("split | terminal glow " .. vim.fn.expand("%"))
end, { desc = "Preview markdown with glow" })

-- open current file in pycharm LightEdit (renders markdown preview)
keymap.set("n", "<leader>mo", function()
  vim.fn.jobstart({ "pycharm", "-e", vim.fn.expand("%:p") }, { detach = true })
end, { desc = "Open current file in pycharm" })

-- open current working directory as a project in pycharm
keymap.set("n", "<leader>popy", function()
  vim.fn.jobstart({ "pycharm", vim.fn.getcwd() }, { detach = true })
end, { desc = "Open current project in pycharm" })

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.keymap.set("n", "q", "<cmd>bd!<cr>", { buffer = true })
  end,
})

