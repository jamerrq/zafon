-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- customizations
vim.opt.clipboard = "unnamedplus"                         -- sync clipboard
vim.opt.colorcolumn = "80,120"                            -- ruler
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#AACDDC" }) -- ruler's color
vim.opt.relativenumber = true                             -- relative numbers
