-- Markdown and notes support
-- Beautiful rendering, zen mode, and obsidian-like features
return {
  -- Render markdown beautifully
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown", "Avante" },
    opts = {
      heading = {
        enabled = true,
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      code = {
        enabled = true,
        sign = true,
        style = "full",
        width = "block",
        left_pad = 2,
        right_pad = 2,
      },
      bullet = {
        enabled = true,
        icons = { "●", "○", "◆", "◇" },
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰄲 " },
      },
      pipe_table = {
        enabled = true,
        style = "full",
      },
    },
  },

  -- Zen mode for distraction-free writing
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = {
        width = 90,
        options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          cursorline = false,
        },
      },
      plugins = {
        gitsigns = { enabled = false },
        tmux = { enabled = false },
        wezterm = {
          enabled = true,
          font = "+4", -- Increase font size
        },
      },
    },
  },

  -- Twilight - dim inactive portions of code
  {
    "folke/twilight.nvim",
    cmd = "Twilight",
    keys = {
      { "<leader>tw", "<cmd>Twilight<cr>", desc = "Toggle Twilight" },
    },
    opts = {
      dimming = {
        alpha = 0.25,
      },
      context = 15,
    },
  },

  -- Obsidian.nvim for note-taking (optional, uncomment if you use Obsidian)
  -- {
  --   "epwalsh/obsidian.nvim",
  --   version = "*",
  --   lazy = true,
  --   ft = "markdown",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --   },
  --   opts = {
  --     workspaces = {
  --       {
  --         name = "notes",
  --         path = "~/Documents/Notes",
  --       },
  --     },
  --   },
  -- },

  -- Better markdown editing
  {
    "preservim/vim-markdown",
    ft = "markdown",
    dependencies = { "godlygeek/tabular" },
    init = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_conceal = 0
      vim.g.vim_markdown_frontmatter = 1
      vim.g.vim_markdown_strikethrough = 1
      vim.g.vim_markdown_new_list_item_indent = 2
    end,
  },
}
