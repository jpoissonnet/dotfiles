return {
	"ibhagwan/fzf-lua",
	opts = function(_, opts)
		local actions = require("fzf-lua").actions

		opts.files = vim.tbl_deep_extend("force", opts.files or {}, {
			cwd_prompt = false,
			fd_opts = "--color=never --type f --follow --exclude .git",
			actions = {
				["alt-i"] = { actions.toggle_ignore },
				["alt-h"] = false,
				["ctrl-h"] = { actions.toggle_hidden },
			},
		})

		opts.grep = vim.tbl_deep_extend("force", opts.grep or {}, {
			rg_opts = "--column --hidden --line-number --no-heading --color=always --smart-case --max-columns=4096 --glob=!.git",
			actions = {
				["alt-i"] = { actions.toggle_ignore },
				["alt-h"] = false,
				["ctrl-h"] = { actions.toggle_hidden },
			},
		})

		return opts
	end,
}
