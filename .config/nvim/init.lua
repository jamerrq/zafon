-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Zafon Customizations
vim.opt.clipboard = "unnamedplus"                         -- sync clipboard
vim.opt.colorcolumn = "80,120"                            -- ruler
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#AACDDC" }) -- ruler's color
vim.opt.relativenumber = true                             -- relative numbers

-- Move selected lines up and down in Visual Mode
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })

-- Move current line up and down in Normal Mode
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move current line down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move current line up" })
