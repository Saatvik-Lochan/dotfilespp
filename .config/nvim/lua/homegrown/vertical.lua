local M = {}
 
M.keys = "arstneio"

M.move_percent = function(amount)
  local start = vim.fn.line('w0')
  local last = vim.fn.line('w$')
  local pos = start + amount * (last - start)

  vim.api.nvim_win_set_cursor(0, {pos, 0})
end

M.do = function(keys) 

end

M.move_percent(0.6)

return M
