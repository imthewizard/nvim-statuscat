local M = {}

---@param opts NvimStatusCatConfig
function M.start_rendering(opts)
	local images = require("nvim-statuscat.images")
	images.init(opts)

	local cur_win = vim.api.nvim_get_current_win()
	images.track_win(cur_win)
	images.update_win(cur_win)

	local group = vim.api.nvim_create_augroup("StatuslineCat", {clear = true})

	vim.api.nvim_create_autocmd("WinNew", {
		group = group,
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not require("nvim-statuscat.utils").is_window_normal(win_id) then return end
			images.track_win(win_id)
			images.update_all_windows()
		end,
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			local win_id = tonumber(args.match)
			if win_id then
				images.untrack_win(win_id)
				images.update_all_windows()
			end
		end,
	})

	local is_animated = #opts.foreground_img_path > 1
	if is_animated then
		if not opts.fps then vim.notify("nvim-statuscat: missing fps in options", vim.log.levels.ERROR) return end
		local timer = vim.uv.new_timer()
		if not timer then vim.notify("nvim-statuscat: error with vim.uv.new_timer()", vim.log.levels.ERROR) return end
		timer:start(0, (1000 / opts.fps), vim.schedule_wrap(function()
			images.next_frame()
			images.update_all_windows()
		end))
	else
		vim.api.nvim_create_autocmd({"CursorMoved"}, {
			group = group,
			callback = function()
				local win_id = vim.api.nvim_get_current_win()
				if not require("nvim-statuscat.utils").is_window_normal(win_id) then return end
				images.update_win(win_id)
			end,
		})
	end

end

return M
