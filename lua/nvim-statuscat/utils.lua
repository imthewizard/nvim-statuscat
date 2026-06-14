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

function M.get_buffer_percentage(win_id)
	local current_line = vim.api.nvim_win_get_cursor(win_id)[1]
	local total_lines = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win_id))

	if total_lines == 0 then return 0 end

	return (current_line / total_lines) * 100
end

return M
