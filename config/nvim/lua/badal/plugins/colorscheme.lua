return {
  "folke/tokyonight.nvim",
  lazy = false, -- load during startup, not on demand
  priority = 1000, -- load before any other plugin draws
  opts = {
    style = "night",
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
