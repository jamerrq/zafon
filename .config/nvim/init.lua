-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- nikki customizations
vim.opt.clipboard = "unnamedplus" -- sync vim clipboard with the system's one
vim.opt.colorcolumn = "80,120" -- ruler
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#AACDDC" }) -- ruler's color
