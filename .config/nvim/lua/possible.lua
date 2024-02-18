-- [[ Configure UFO ]]
vim.o.foldopen = vim.o.foldopen .. ",jump"
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

require('ufo').setup({
  provider_selector = function(bufnr, filetype, buftype)
    return { 'treesitter', 'indent' }
  end
})

vim.keymap.set('n', 'K', function()
  local winid = require('ufo').peekFoldedLinesUnderCursor()
  if not winid then
    vim.lsp.buf.hover()
  end
end)

vim.keymap.set('n', '<Leader>ha', require('ufo').closeAllFolds, { desc = '[H]ide [A]ll' })
vim.keymap.set('n', '<Tab>', 'za', { desc = 'Just easy to reach bro...' })
vim.keymap.set('n', '<S-Tab>', 'zA', { desc = 'Just easy to reach bro...' })
