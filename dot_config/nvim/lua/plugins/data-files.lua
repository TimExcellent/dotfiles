-- Data file viewing: CSV, Parquet, PDF
return {
  -- CSV/TSV column coloring and RBQL queries
  { "mechatroner/rainbow_csv" },

  -- Autocmds for binary/special file types
  {
    "nvim-lua/plenary.nvim",
    init = function()
      local augroup = vim.api.nvim_create_augroup("DataFiles", { clear = true })

      -- Parquet files: open in duckdb terminal
      vim.api.nvim_create_autocmd("BufReadCmd", {
        group = augroup,
        pattern = "*.parquet",
        callback = function(args)
          vim.cmd("enew")
          vim.cmd("terminal duckdb -c \"SELECT * FROM '" .. args.file .. "' LIMIT 100\"")
          vim.bo.bufhidden = "wipe"
        end,
      })

      -- PDF files: extract text via pdftotext
      vim.api.nvim_create_autocmd("BufReadCmd", {
        group = augroup,
        pattern = "*.pdf",
        callback = function(args)
          local content = vim.fn.systemlist({ "pdftotext", "-layout", args.file, "-" })
          vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, content)
          vim.bo[args.buf].modifiable = false
          vim.bo[args.buf].filetype = "text"
          vim.bo[args.buf].buftype = "nofile"
        end,
      })

      -- Open PDF in Preview.app (macOS)
      vim.keymap.set("n", "<leader>fp", function()
        local file = vim.fn.expand("%:p")
        if file:match("%.pdf$") then
          vim.fn.system({ "open", "-a", "Preview", file })
        end
      end, { desc = "Open PDF in Preview.app" })
    end,
  },
}
