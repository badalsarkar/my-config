return {
  "nvim-treesitter/nvim-treesitter",
  event = {"BufReadPre", "BufNewFile"},
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function ()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({
      -- enable better syntax highlight
      highlight = {
        enable = true,
      },
      indent = {enable = true},
      -- enable autotagging (with nvim-ts-autotag plugin)
      autotag = {
        enable = true
      },
      --
      ensure_installed = {
        "json",
        "java",
        "python",
        "javascript",
        "typescript",
        "yaml",
        "html",
        "markdown",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>"
        },
      },
    })
  end,
}
