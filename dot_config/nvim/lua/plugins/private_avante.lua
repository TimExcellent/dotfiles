-- avante.nvim - Cursor-like AI in Neovim
-- Uses Claude via your Claude Max subscription
return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  opts = {
    -- Use Claude as the provider
    provider = "claude",
    auto_suggestions_provider = "claude",

    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-sonnet-4-20250514",
      temperature = 0,
      max_tokens = 4096,
    },

    -- Behavior settings
    behaviour = {
      auto_suggestions = false, -- Disable auto-suggestions (too noisy)
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
    },

    -- Keymaps (leader = space by default in LazyVim)
    mappings = {
      ask = "<leader>aa", -- Ask AI about code
      edit = "<leader>ae", -- Edit selected code with AI
      refresh = "<leader>ar", -- Refresh AI response
      focus = "<leader>af", -- Focus AI window
      toggle = {
        default = "<leader>at", -- Toggle AI sidebar
        debug = "<leader>ad", -- Toggle debug mode
        hint = "<leader>ah", -- Toggle inline hints
        suggestion = "<leader>as", -- Toggle suggestions
      },
      diff = {
        ours = "co", -- Choose our version
        theirs = "ct", -- Choose AI's version
        both = "cb", -- Keep both versions
        cursor = "cc", -- Choose at cursor
        next = "]x", -- Next diff
        prev = "[x", -- Previous diff
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
    },

    -- UI hints
    hints = {
      enabled = true,
    },

    -- Window settings
    windows = {
      position = "right",
      wrap = true,
      width = 40,
      sidebar_header = {
        align = "center",
        rounded = true,
      },
    },
  },

  -- Build from source (required for some features)
  build = "make",

  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
