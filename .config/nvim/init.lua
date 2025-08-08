-- ==============================
-- neovim minimal config
-- ==============================

-- mostrar números absolutos y relativos
vim.opt.number = true
vim.opt.relativenumber = true

-- que la numeración relativa solo esté activa en modo normal
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.opt.relativenumber = false
  end
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.opt.relativenumber = true
  end
})

-- otras opciones básicas recomendadas
vim.opt.tabstop = 4       -- número de espacios que representa un tab
vim.opt.shiftwidth = 4    -- número de espacios al hacer indentación
vim.opt.expandtab = true  -- usar espacios en lugar de tabs
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.cursorline = true -- resaltar la línea actual
