-- Gruvbox colorscheme with easy switching
-- Use :colorscheme <Tab> to switch themes
return {
  -- Gruvbox Material (recommended variant)
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "hard" -- hard, medium, soft
      vim.g.gruvbox_material_foreground = "material" -- material, mix, original
      vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_enable_bold = true
      vim.g.gruvbox_material_better_performance = true
    end,
  },

  -- Original Gruvbox (alternative)
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = {
      contrast = "hard",
      italic = {
        strings = false,
        comments = true,
        operators = false,
      },
    },
  },

  -- Tokyo Night (popular alternative)
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
    },
  },

  -- Catppuccin (another popular choice)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = "mocha",
    },
  },

  -- Set Gruvbox Material as default
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox-material",
    },
  },
}
