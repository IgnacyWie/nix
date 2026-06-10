-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.keymap
local opts = { noremap = true, silent = true }
local silent = { silent = true }

-- Increment/decrement number
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
keymap.set("n", "dw", "vb_d")

-- Select All
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist
keymap.set("n", "<C-m>", "<C-i>", opts)

keymap.set("n", "<leader>t", ":TypstPreview<Return>", opts)

-- Polish diacritics mappings
keymap.set("i", "`a", "ą", { desc = "Polish ą" })
keymap.set("i", "`c", "ć", { desc = "Polish ć" })
keymap.set("i", "`e", "ę", { desc = "Polish ę" })
keymap.set("i", "`l", "ł", { desc = "Polish ł" })
keymap.set("i", "`n", "ń", { desc = "Polish ń" })
keymap.set("i", "`o", "ó", { desc = "Polish ó" })
keymap.set("i", "`s", "ś", { desc = "Polish ś" })
keymap.set("i", "`z", "ź", { desc = "Polish ź" })
keymap.set("i", "`x", "ż", { desc = "Polish ż" })

keymap.set("i", "`A", "Ą", { desc = "Polish Ą" })
keymap.set("i", "`C", "Ć", { desc = "Polish Ć" })
keymap.set("i", "`E", "Ę", { desc = "Polish Ę" })
keymap.set("i", "`L", "Ł", { desc = "Polish Ł" })
keymap.set("i", "`N", "Ń", { desc = "Polish Ń" })
keymap.set("i", "`O", "Ó", { desc = "Polish Ó" })
keymap.set("i", "`S", "Ś", { desc = "Polish Ś" })
keymap.set("i", "`Z", "Ź", { desc = "Polish Ź" })
keymap.set("i", "`X", "Ż", { desc = "Polish Ż" })
