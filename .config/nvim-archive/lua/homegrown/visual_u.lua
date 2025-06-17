local M = {}

function M.on_bytes(
  ignored, ---@diagnostic disable-line
  bufnr, ---@diagnostic disable-line
  changedtick, ---@diagnostic disable-line
  start_row, ---@diagnostic disable-line,
  start_column, ---@diagnostic disable-line,
  byte_offset, ---@diagnostic disable-line
  old_end_row, ---@diagnostic disable-line
  old_end_col, ---@diagnostic disable-line
  old_end_byte, ---@diagnostic disable-line
  new_end_row, ---@diagnostic disable-line
  new_end_col, ---@diagnostic disable-line
  new_end_byte ---@diagnostic disable-line
)

  vim.schedule(function() 
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_column })
    vim.api.nvim_feedkeys("v" .. new_end_row .. "j" .. new_end_col .. "l", 'n', true)
  end)

  return true
end

function M.visual_undo()
  vim.api.nvim_buf_attach(0, false, {
    on_bytes = M.on_bytes,
  })

  vim.api.nvim_feedkeys("u", 'n', true)
end

return M
