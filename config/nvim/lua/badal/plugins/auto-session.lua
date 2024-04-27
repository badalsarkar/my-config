return {
  "rmagatti/auto-session",
  config = function()
    local auto_session = require ("auto-session")

    auto_session.setup({
      -- sessions will not be restored automatically
      auto_session_enabled = false,
      -- auto session will not apply for these directories
      auto_session_suppress_dirs = {"~/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

      --keymap
      local keymap = vim.keymap

      keymap.set("n", "<leader>wr", "<cmd>SessionRestore<CR>", { desc = "Restore session for cwd" })
      keymap.set("n", "<leader>ws", "<cmd>SessionSave<CR>", { desc = "Save session for auto session root dir" })
  end
}

