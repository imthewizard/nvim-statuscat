local M = {}

---@return boolean # If the window is just a normal non-floating window
function M.is_window_normal(win_id)
	if not (vim.api.nvim_win_is_valid(win_id)) then return false end

	local win_config = vim.api.nvim_win_get_config(win_id)
	local is_floating = win_config.relative ~= "" or win_config.external

	if is_floating then return false end

	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local buftype = vim.bo[buf_id].buftype
	if buftype ~= "" then return false end

	local modifiable = vim.bo[buf_id].modifiable
	if not modifiable then return false end

	local readonly = vim.bo[buf_id].readonly
	if readonly then return false end

	return true
end

---@return number # Percentage of position inside buffer (0 for top, 100 for bottom)
function M.get_buffer_percentage(win_id)
	local current_line = vim.api.nvim_win_get_cursor(win_id)[1]
	local total_lines = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win_id))

	if total_lines == 0 then return 0 end

	return (current_line / total_lines) * 100
end

---@return boolean # If the user has a global statusline instead of 1 per window
function M.has_global_statusline()
	return vim.o.laststatus == 3;
end

---@return boolean supports # If there is vim.ui.img and if the terminal supports images
---@return string? message # Error message, if supports is false
function M.supports_img()
	local term = string.lower(os.getenv("TERM"))

	local supports = term == "wezterm" or term == "xterm-kitty" or term == "ghostty"
	local has_vim_img = vim.ui.img

	if supports and has_vim_img then return true, nil end

	if supports and not has_vim_img then
		return false, "Missing vim.ui.img, Neovim >= 0.13 is required!"
	end

	if not supports and has_vim_img then
		return false, "Missing image support for the terminal. Use WezTerm, Kitty or Ghostty."
	end

	return false, "Missing both vim.ui.img and image support for the terminal. Upgrade Neovim to >= 0.13 and use WezTerm, Kitty or Ghostty."
end

return M
