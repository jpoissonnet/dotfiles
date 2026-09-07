return {
  "stevearc/conform.nvim",
  opts = {
    formatters = {
      prettier = {
        require_cwd = true,
      },
    },
  },
  init = function()
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.b.autoformat = false
      else
        vim.g.autoformat = false
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.autoformat = true
      vim.g.autoformat = true
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  end,
}
