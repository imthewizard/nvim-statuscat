local M = {}

local bars_per_window = 15

---@type table<number, number[]>
local loaded_backgrounds = {}
---@type table<number, number[]>
local loaded_progress_bars = {}
---@type table<number, number[]>
local loaded_foregrounds = {}

---@type string
local background_img = ""
---@type string[]
local foreground_imgs = {}
---@type string
local progress_img = ""

local next_frame = 1
local max_frames = nil

---@type NvimStatusCatConfig
local loaded_opts = nil

local function win_has_required_width(win_width)
	return win_width >= loaded_opts.min_window_width
end

local function create_background(win_id, row, col)
	local new_id = vim.ui.img.set(
		background_img,
		{ row = row, col = col, width = loaded_opts.width, height = loaded_opts.height, zindex=1}
	)
	table.insert(loaded_backgrounds[win_id], new_id)
end

local function create_progress_bar(win_id, row, col)
	local new_id = vim.ui.img.set(
		progress_img,
		{ row = row, col = col, width = loaded_opts.width, height = loaded_opts.height, zindex=2}
	)
	table.insert(loaded_progress_bars[win_id], new_id)
end

local function create_foreground(win_id, row, col)
	local new_id = vim.ui.img.set(
		foreground_imgs[next_frame],
		{ row = row, col = col, width = loaded_opts.foreground_width, height = loaded_opts.height, zindex=3}
	)
	table.insert(loaded_foregrounds[win_id], new_id)
end

local function new_imgs_for_win(win_id)
	assert(loaded_opts ~= nil, "Forgot to init images.lua")

	local win_percentage = require("nvim-statuscat.utils").get_buffer_percentage(win_id)
	local completed_bars = math.floor(win_percentage / 100 * bars_per_window)

	local pos = vim.api.nvim_win_get_position(win_id)
	local win_width = vim.api.nvim_win_get_width(win_id)
	local win_height = vim.api.nvim_win_get_height(win_id)

	if not win_has_required_width(win_width) then return end

	local img_width = loaded_opts.width

	local img_start_pos = (win_width * loaded_opts.position)
	local row_pos = pos[1] + win_height + 1
	local col_pos = math.floor(pos[2] + img_start_pos)

	-- All windows will one background image in every position
	loaded_backgrounds[win_id] = {}
	for i = 1, bars_per_window do
		local offset = math.floor((i - (bars_per_window / 2)) * img_width)
		create_background(win_id, row_pos, col_pos + offset)
	end

	-- Windows will only have the needed progress bars and foregrounds
	loaded_progress_bars[win_id] = {}
	loaded_foregrounds[win_id] = {}
	for i = 1, bars_per_window do
		local offset = math.floor((i - (bars_per_window / 2)) * img_width)

		if (i < completed_bars) then
			create_progress_bar(win_id, row_pos, col_pos + offset)
		elseif (i == completed_bars) then
			create_foreground(win_id, row_pos, col_pos + offset)
		end
	end
end

---@param opts NvimStatusCatConfig
function M.init(opts)
	loaded_opts = opts
	progress_img = vim.fn.readblob(opts.progress_img_path)
	background_img = vim.fn.readblob(opts.background_img_path)

	local amount_of_fgs = #opts.foreground_img_path
	max_frames = amount_of_fgs
	if amount_of_fgs > 1 then
		-- Animated
		for i = 1, amount_of_fgs do
			table.insert(foreground_imgs, vim.fn.readblob(opts.foreground_img_path[i]))
		end
	else
		-- Static
		foreground_imgs = {vim.fn.readblob(opts.foreground_img_path[1])}
	end
end

function M.delete_win(win_id)
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

function M.update_win(win_id)
	M.delete_win(win_id)
	new_imgs_for_win(win_id)
end

function M.update_all_windows()
	for _, win_id in pairs (vim.api.nvim_list_wins()) do
		if require("nvim-statuscat.utils").is_window_normal(win_id) then
			M.update_win(win_id)
		end
	end
end

function M.next_frame()
	if max_frames > 1 then
		next_frame = next_frame + 1
		if next_frame > max_frames then next_frame = 1 end
	end
end

return M
