local M = {}

---@type integer[] List of window ids
local tracked_windows = {}

---@type table<integer, integer[]> Loaded background images
local loaded_backgrounds = {}
---@type table<integer, integer[]> Loaded progress bar images
local loaded_progress_bars = {}
---@type table<integer, integer[]> Loaded foreground images
local loaded_foregrounds = {}

---@type string Loaded background image
local background_img = nil
---@type string[] Loaded foreground image(s)
local foreground_imgs = nil
---@type string Loaded progress bar image
local progress_img = nil

---@type integer Frame that will be used for the foreground in the next update
local next_fg_frame = 1
---@type integer Amount of foreground frames loaded
local amount_of_fg_frames = nil

---@type NvimStatusCatConfig User options
local loaded_opts = nil


---@return boolean # If the width is enough acording to the loaded options
local function has_required_width(win_width)
	return win_width >= loaded_opts.min_window_width
end

---Clear the backgrounds, progress bar and foreground of win_id
local function clear_win(win_id)
	if loaded_backgrounds[win_id] then
		vim.ui.img.del(loaded_backgrounds[win_id][1])
	end
	if loaded_progress_bars[win_id] then
		vim.ui.img.del(loaded_progress_bars[win_id][1])
	end
	if loaded_foregrounds[win_id] then
		vim.ui.img.del(loaded_foregrounds[win_id][1])
	end
end

---Clear all the backgrounds, progress bars and foregrounds
local function clear_all_wins()
	for win_id, _ in pairs(loaded_backgrounds) do
		vim.ui.img.del(loaded_backgrounds[win_id][1])
	end
	for win_id, _ in pairs(loaded_progress_bars) do
		vim.ui.img.del(loaded_progress_bars[win_id][1])
	end
	for win_id, _ in pairs(loaded_foregrounds) do
		vim.ui.img.del(loaded_foregrounds[win_id][1])
	end
end

---Redraws the background, progress and foreground images for the specified window
local function redraw_win_images(win_id)
	local utils = require("nvim-statuscat.utils")

	local pos, win_width, win_height
	if utils.has_global_statusline() then
		win_width = vim.o.columns
		win_height = vim.o.lines - 1 - vim.o.cmdheight
		pos = {0, 0}
	else
		win_width = vim.api.nvim_win_get_width(win_id)
		win_height = vim.api.nvim_win_get_height(win_id)
		pos = vim.api.nvim_win_get_position(win_id)
	end

	if not has_required_width(win_width) then return end

	local bar_length = loaded_opts.bar_length_per_window
	local win_percentage = utils.get_buffer_percentage(win_id)
	local completed_bars = math.floor(win_percentage / 100 * bar_length)

	local img_width = loaded_opts.width
	local img_height = loaded_opts.height

	local row_pos = pos[1] + win_height + 1 -- Should be the statusline row
	local bar_center = pos[2] + (win_width * loaded_opts.position) -- Center of the bar
	local bar_left = bar_center - img_width * loaded_opts.bar_length_per_window / 2

	loaded_backgrounds[win_id] = {}
	local background_id = vim.ui.img.set(
		background_img,
		{
			row = row_pos, col = bar_left,
			width = loaded_opts.width * bar_length, height = img_height, zindex=1
		}
	)
	table.insert(loaded_backgrounds[win_id], background_id)

	if completed_bars > 0 then
		loaded_progress_bars[win_id] = {}
		local progress_id = vim.ui.img.set(
			progress_img,
			{
				row = row_pos, col = bar_left,
				width = loaded_opts.width * (completed_bars - 1), height = img_height, zindex=2
			}
		)
		table.insert(loaded_progress_bars[win_id], progress_id)

		loaded_foregrounds[win_id] = {}
		local foreground_id = vim.ui.img.set(
			foreground_imgs[next_fg_frame],
			{
				row = row_pos, col = bar_left + loaded_opts.width * (completed_bars - 1),
				width = loaded_opts.foreground_width, height = img_height, zindex=3
			}
		)
		table.insert(loaded_foregrounds[win_id], foreground_id)
	end
end

---Loads the all the image files
---@param opts NvimStatusCatConfig
function M.init(opts)
	loaded_opts = opts
	progress_img = vim.fn.readblob(opts.progress_img_path)
	background_img = vim.fn.readblob(opts.background_img_path)

	foreground_imgs = {}
	amount_of_fg_frames = #opts.foreground_img_path
	if amount_of_fg_frames > 1 then
		-- Animated
		for i = 1, amount_of_fg_frames do
			table.insert(foreground_imgs, vim.fn.readblob(opts.foreground_img_path[i]))
		end
	else
		-- Static
		foreground_imgs = {vim.fn.readblob(opts.foreground_img_path[1])}
	end
end

---Adds a window to be tracked. In the next update, the window will receive the images
---@param win_id integer # Window id
function M.track_win(win_id)
	table.insert(tracked_windows, win_id)
end

---Untracks a window and deletes its images
---@param win_id integer # Window id
function M.untrack_win(win_id)
	clear_win(win_id)
	for i, v in pairs(tracked_windows) do
		if v == win_id then
			table.remove(tracked_windows, i)
			return
		end
	end
end

---Clears the window's images and redraws it
---@param win_id integer # Window id
function M.update_win(win_id)
	if require("nvim-statuscat.utils").has_global_statusline() then
		clear_all_wins()
	else
		clear_win(win_id)
	end
	redraw_win_images(win_id)
end

---Calls update_win for every tracked window
function M.update_all_windows()
	if require("nvim-statuscat.utils").has_global_statusline() then
		M.update_win(vim.api.nvim_get_current_win())
	else
		for _, win_id in pairs (tracked_windows) do
			M.update_win(win_id)
		end
	end
end

---Cycles the frame of the foreground. Does not call update
function M.next_frame()
	if amount_of_fg_frames > 1 then
		next_fg_frame = next_fg_frame + 1
		if next_fg_frame > amount_of_fg_frames then next_fg_frame = 1 end
	end
end

return M
