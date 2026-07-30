vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.tex",
  callback = function()
    local build_script = vim.fn.getcwd() .. "/build.sh"

    if vim.fn.executable(build_script) ~= 1 then
      vim.api.nvim_echo({
        { "No executable ./build.sh found in cwd", "WarningMsg" },
      }, false, {})
      return
    end

    vim.fn.jobstart({ build_script }, {
      cwd = vim.fn.getcwd(),
      stdout_buffered = true,
      stderr_buffered = true,

      on_exit = function(_, code)
        if code == 0 then
          vim.schedule(function()
            vim.api.nvim_echo({
              { "LaTeX build succeeded", "MoreMsg" },
            }, false, {})
          end)
        else
          vim.schedule(function()
            vim.api.nvim_echo({
              { "LaTeX build failed with exit code " .. code, "ErrorMsg" },
            }, false, {})
          end)
        end
      end,
    })
  end,
})
