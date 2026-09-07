return {
	"folke/snacks.nvim",
	opts = function(_, opts)
		---`gh api` defaults to github.com and does *not* infer GitHub
		---Enterprise hosts from the cwd, so resolve the host from the
		---`origin` remote ourselves and pass it explicitly via `--hostname`.
		---@param cwd string
		---@return string?
		local function get_git_host(cwd)
			local out = vim.fn.system({ "git", "-C", cwd, "remote", "get-url", "origin" })
			if vim.v.shell_error ~= 0 then
				return nil
			end
			out = vim.trim(out)
			return out:match("^git@([^:/]+)[:/]")
				or out:match("^ssh://[^@/]+@([^:/]+)")
				or out:match("^ssh://([^:/]+)")
				or out:match("^https?://[^@/]+@([^/]+)/")
				or out:match("^https?://([^/]+)/")
		end

		---Open the GitHub pull request associated with the selected commit
		---(if any) in the browser. Requires the `gh` CLI to be installed and
		---authenticated against the commit's remote.
		---@param picker snacks.Picker
		---@param item snacks.picker.Item
		local function git_pr_browse(picker, item)
			local sha = item and item.commit
			if not sha then
				return Snacks.notify.warn("No commit found under cursor", { title = "Git PR" })
			end
			local cwd = picker:cwd() or vim.fn.getcwd()
			local host = get_git_host(cwd)
			picker:close()
			local cmd = { "gh", "api" }
			if host then
				vim.list_extend(cmd, { "--hostname", host })
			end
			vim.list_extend(cmd, { ("repos/{owner}/{repo}/commits/%s/pulls"):format(sha), "--jq", ".[0].html_url" })
			vim.system(cmd, { text = true, cwd = cwd }, function(out)
				vim.schedule(function()
					local url = out.code == 0 and vim.trim(out.stdout or "") or ""
					if url == "" or url == "null" then
						Snacks.notify.warn(
							("No pull request found for commit %s"):format(sha:sub(1, 7)),
							{ title = "Git PR" }
						)
						return
					end
					vim.ui.open(url)
				end)
			end)
		end

		opts.picker = opts.picker or {}
		opts.picker.sources = opts.picker.sources or {}
		for _, source in ipairs({ "git_log", "git_log_file", "git_log_line" }) do
			opts.picker.sources[source] = vim.tbl_deep_extend("force", opts.picker.sources[source] or {}, {
				actions = { git_pr_browse = git_pr_browse },
				win = {
					input = {
						keys = {
							["<c-o>"] = { "git_pr_browse", mode = { "n", "i" }, desc = "Open PR on GitHub" },
						},
						-- show a persistent "<c-o> Open PR on GitHub" hint in the
						-- input window's footer (in addition to the full keymap
						-- list available via `?`)
						footer_keys = { "<c-o>" },
					},
				},
			})
		end

		return opts
	end,
}
