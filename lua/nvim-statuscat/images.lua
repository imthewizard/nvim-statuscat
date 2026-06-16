local M = {}

---@type integer[] List of window ids
local tracked_windows = {}

---@type table<integer, integer[]> Loaded background images
local loaded_backgrounds = {}
---@type table<integer, integer[]> Loaded progress bar images
local loaded_progress_bars = {}
---@type table<integer, integer[]> Loaded foreground images
local loaded_foregrounds = {}

--- Loaded background image
local background_img = nil
--- Loaded foreground image(s)
local foreground_imgs = {}
--- Loaded progress bar image
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

---Creates a background image at row and col for win_id
local function create_background(win_id, row, col)
	assert(background_img ~= nil, "background_img not loaded")
	local new_id = vim.ui.img.set(
		background_img,
		{ row = row, col = col, width = loaded_opts.width, height = loaded_opts.height, zindex=1}
	)
	table.insert(loaded_backgrounds[win_id], new_id)
end

---Creates a progress bar image at row and col for win_id
local function create_progress_bar(win_id, row, col)
	assert(progress_img ~= nil, "progress_img not loaded")
	local new_id = vim.ui.img.set(
		progress_img,
		{ row = row, col = col, width = loaded_opts.width, height = loaded_opts.height, zindex=2}
	)
	table.insert(loaded_progress_bars[win_id], new_id)
end

---Creates a foreground image at row and col for win_id
local function create_foreground(win_id, row, col)
	assert(#foreground_imgs > 0, "foreground_imgs not loaded")
	local new_id = vim.ui.img.set(
		foreground_imgs[next_fg_frame],
		{ row = row, col = col, width = loaded_opts.foreground_width, height = loaded_opts.height, zindex=3}
	)
	table.insert(loaded_foregrounds[win_id], new_id)
end

---Clear the backgrounds, progress bar and foreground of win_id
local function clear_win(win_id)
	if loaded_backgrounds[win_id] then
		for _, img_id in pairs(loaded_backgrounds[win_id]) do
			vim.ui.img.del(img_id)
		end
	end
	if loaded_progress_bars[win_id] then
		for _, img_id in pairs(loaded_progress_bars[win_id]) do
			vim.ui.img.del(img_id)
		end
	end
	if loaded_foregrounds[win_id] then
		for _, img_id in pairs(loaded_foregrounds[win_id]) do
			vim.ui.img.del(img_id)
		end
	end
end

---Redraws the background, progress and foreground images for the specified window
local function redraw_win_images(win_id)
	assert(loaded_opts ~= nil, "Forgot to init images.lua")

	local win_width = vim.api.nvim_win_get_width(win_id)
	local win_height = vim.api.nvim_win_get_height(win_id)

	if not has_required_width(win_width) then return end

	local bar_length = loaded_opts.bar_length_per_window
	local win_percentage = require("nvim-statuscat.utils").get_buffer_percentage(win_id)
	local completed_bars = math.floor(win_percentage / 100 * bar_length)

	local pos = vim.api.nvim_win_get_position(win_id)
	local img_width = loaded_opts.width

	local row_pos = pos[1] + win_height + 1 -- Should be the statusline row
	local img_start_pos = (win_width * loaded_opts.position)
	local col_pos = math.floor(pos[2] + img_start_pos)

	-- All windows will one background image in every position
	loaded_backgrounds[win_id] = {}
	for i = 1, bar_length do
		local offset = math.floor((i - (bar_length / 2)) * img_width)
		create_background(win_id, row_pos, col_pos + offset)
	end

	-- Windows will only have the needed progress bars and foregrounds
	loaded_progress_bars[win_id] = {}
	loaded_foregrounds[win_id] = {}
	for i = 1, bar_length do
		local offset = math.floor((i - (bar_length / 2)) * img_width)

		if (i < completed_bars) then
			create_progress_bar(win_id, row_pos, col_pos + offset)
		elseif (i == completed_bars) then
			create_foreground(win_id, row_pos, col_pos + offset)
			return
		end
	end
end

---Loads the all the image files
---@param opts NvimStatusCatConfig
function M.init(opts)
	loaded_opts = opts
	progress_img = vim.fn.readblob(opts.progress_img_path)
	background_img = vim.fn.readblob(opts.background_img_path)

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
	clear_win(win_id)
	redraw_win_images(win_id)
end

---Calls update_win for every tracked window
function M.update_all_windows()
	for _, win_id in pairs (tracked_windows) do
		M.update_win(win_id)
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
