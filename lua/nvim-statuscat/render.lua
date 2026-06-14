local M = {}

---@param opts NvimStatusCatConfig
function M.start_rendering(opts)
	local cur_win = vim.api.nvim_get_current_win()

	local images = require("nvim-statuscat.images")
	images.init(opts)
	images.update_win(cur_win)

	local group = vim.api.nvim_create_augroup("StatuslineCat", {clear = true})
	vim.api.nvim_create_autocmd({"CursorMoved", "TextChangedI"}, {
		group = group,
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not require("nvim-statuscat.utils").is_window_normal(win_id) then return end
			images.update_win(win_id)
		end,
	})
	vim.api.nvim_create_autocmd("WinNew", {
		group = group,
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not require("nvim-statuscat.utils").is_window_normal(win_id) then return end
			images.update_all_windows()
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function()
			local win_id = vim.api.nvim_get_current_win()
			if not require("nvim-statuscat.utils").is_window_normal(win_id) then return end
			images.delete_win(win_id)
		end,
	})
end

return M
