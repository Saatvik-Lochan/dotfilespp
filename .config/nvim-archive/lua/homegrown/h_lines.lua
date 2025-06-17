local M = {}

DrawHighlight = function(line, highlight)
  local bufh = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufh, false, {
    relative = "win",
    width = vim.api.nvim_win_get_width(0),
    height = 1,
    border = "single",
    row = line,
    col = 0,
    anchor = "NW",
    focusable = false,
    zindex = 1,
    style = "minimal",
    noautocmd = true,
  })

  vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:' .. highlight)
  vim.api.nvim_win_set_option(win_id, "winblend", 1)

  return win_id
end

vim.api.nvim_set_hl(0, "GreenHighlight", { bg = "lightgreen", blend = 90 })
vim.api.nvim_set_hl(0, "RedHighlight", { bg = "lightred", blend = 90 })
vim.api.nvim_set_hl(0, "BlueHighlight", { bg = "lightblue", blend = 90 })

DrawHighlight(5, "GreenHighlight")
DrawHighlight(10, "RedHighlight")
DrawHighlight(15, "GreenHighlight")
DrawHighlight(20, "BlueHighlight")
DrawHighlight(25, "RedHighlight")
DrawHighlight(30, "BlueHighlight")

vim.keymap.set("n", "<leader>b", function() vim.api.nvim_win_set_cursor(0, {10, 0}) end, {})

return

--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
