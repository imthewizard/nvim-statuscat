local M = {}

local timer = vim.uv.new_timer()

---@param opts NvimStatusCatConfig
function M.start_rendering(opts)
	local cur_win = vim.api.nvim_get_current_win()

	local images = require("nvim-statuscat.images")
	images.init(opts)
	images.track_win(cur_win)
	images.update_win(cur_win)

	local group = vim.api.nvim_create_augroup("StatuslineCat", {clear = true})
	if #opts.foreground_img_path == 1 then
		vim.api.nvim_create_autocmd({"CursorMoved", "TextChangedI"}, {
			group = group,
			callback = function()
				local win_id = vim.api.nvim_get_current_win()
				if not require("nvim-statuscat.utils").is_window_normal(win_id) then return end
				images.update_win(win_id)
			end,
		})
	end
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
			images.delete_win(win_id)
			images.update_all_windows()
		end,
	})

	if #opts.foreground_img_path > 1 then
		timer:start(0, (1000 / opts.fps), vim.schedule_wrap(function()
			images.next_frame()
			images.update_all_windows()
		end))
	end
end

return M
