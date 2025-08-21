local opt = vim.opt

opt.relativenumber = true
opt.number = true  -- keep absolute number in the current line

-- special chars rendering
opt.list = true
opt.listchars = {
  tab = ">-",      -- render tabs as >-
  trail = ".",     -- render trailing spaces as .
  extends = "#",   -- render # when the line overflows
  nbsp = ".",      -- render unbreakable spaces as .
  space = "·"      -- render spaces as ·
}

opt.expandtab = true   -- convert tab to spaces
-- opt.tabstop = 2     -- tab width
-- opt.shiftwidth = 2  -- ident width
opt.smartindent = true -- smart ident

-- https://stackoverflow.com/questions/77747363
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    -- save cursor position to restore later
    local curpos = vim.api.nvim_win_get_cursor(0)
    -- search and replace trailing whitespaces
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, curpos)
  end,
})

