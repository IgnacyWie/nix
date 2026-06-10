return {
  -- Molten: code runner + output
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    init = function()
      -- general molten options
      vim.g.molten_auto_open_output = false
      vim.g.molten_image_provider = "none"
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true

      -- keymaps
      local map = vim.keymap.set
      map("n", "<localleader>me", ":MoltenEvaluateOperator<CR>", { desc = "evaluate operator", silent = true })
      map("n", "<localleader>os", ":noautocmd MoltenEnterOutput<CR>", { desc = "open output window", silent = true })
      map("n", "<localleader>rr", ":MoltenReevaluateCell<CR>", { desc = "re-eval cell", silent = true })
      map(
        "v",
        "<localleader>r",
        ":<C-u>MoltenEvaluateVisual<CR>gv",
        { desc = "execute visual selection", silent = true }
      )
      map("n", "<localleader>oh", ":MoltenHideOutput<CR>", { desc = "close output window", silent = true })
      map("n", "<localleader>md", ":MoltenDelete<CR>", { desc = "delete Molten cell", silent = true })
      map("n", "<localleader>mx", ":MoltenOpenInBrowser<CR>", { desc = "open output in browser", silent = true })
    end,
  },

  -- Image rendering is available for notebook-oriented filetypes, but should
  -- not initialize during normal code editing sessions.
  {
    "3rd/image.nvim",
    ft = { "markdown", "quarto", "typst" },
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = { enabled = true, filetypes = { "markdown", "quarto" } },
        typst = { enabled = true, filetypes = { "typst" } },
        asciidoc = { enabled = false },
        neorg = { enabled = false },
        syslang = { enabled = false },
      },
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif" },
    },
  },

  -- Quarto support + otter.nvim integration
  {
    "quarto-dev/quarto-nvim",
    ft = { "quarto", "markdown" },
    dependencies = { "jmbuhr/otter.nvim" },
    config = function()
      local runner = require("quarto.runner")
      local map = vim.keymap.set
      map("n", "<localleader>rc", runner.run_cell, { desc = "run cell", silent = true })
      map("n", "<localleader>ra", runner.run_above, { desc = "run cell and above", silent = true })
      map("n", "<localleader>rA", runner.run_all, { desc = "run all cells", silent = true })
      map("n", "<localleader>rl", runner.run_line, { desc = "run line", silent = true })
      map("v", "<localleader>r", runner.run_range, { desc = "run visual range", silent = true })
      map("n", "<localleader>RA", function()
        runner.run_all(true)
      end, { desc = "run all cells of all languages", silent = true })

      -- automatically activate quarto for markdown
      require("quarto").activate()
    end,
  },

  -- Jupytext: ipynb <-> markdown
  {
    "GCBallesteros/jupytext.nvim",
    config = function()
      require("jupytext").setup({
        style = "markdown",
        output_extension = "md",
        force_ft = "markdown",
      })
    end,
  },
}
