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
---@type string
local foreground_img = ""
---@type string
local progress_img = ""

---@type NvimStatusCatConfig
local loaded_opts = nil

local function win_has_required_width(win_width)
	return win_width >= loaded_opts.min_window_width
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
	local fore_img_width = loaded_opts.foreground_width
	local img_height = loaded_opts.height

	local img_start_pos = (win_width * loaded_opts.position)
	local row_pos = pos[1] + win_height + 1
	local col_pos = math.floor(pos[2] + img_start_pos)

	-- All windows will one background image in every position
	loaded_backgrounds[win_id] = {}
	for i = 1, bars_per_window do
		local offset = math.floor((i - (bars_per_window / 2)) * img_width)

		local new_img = vim.ui.img.set(
			background_img,
			{ row = row_pos, col = col_pos + offset, width = img_width, height = img_height, zindex=1}
		)
		table.insert(loaded_backgrounds[win_id], new_img)
	end

	-- Windows will only have the needed progress bars and foregrounds
	loaded_progress_bars[win_id] = {}
	loaded_foregrounds[win_id] = {}
	for i = 1, bars_per_window do
		local offset = math.floor((i - (bars_per_window / 2)) * img_width)

		if (i < completed_bars) then
			local new_img = vim.ui.img.set(
				progress_img,
				{ row = row_pos, col = col_pos + offset, width = img_width, height = img_height, zindex=2}
			)
			table.insert(loaded_progress_bars[win_id], new_img)
		elseif (i == completed_bars) then
			local new_img = vim.ui.img.set(
				foreground_img,
				{ row = row_pos, col = col_pos + offset, width = fore_img_width, height = img_height, zindex=3}
			)
			table.insert(loaded_foregrounds[win_id], new_img)
		end
	end
end

---@param opts NvimStatusCatConfig
function M.init(opts)
	loaded_opts = opts
	progress_img = vim.fn.readblob(opts.progress_img_path)
	foreground_img = vim.fn.readblob(opts.foreground_img_path)
	background_img = vim.fn.readblob(opts.background_img_path)
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
		M.update_win(win_id)
	end
end

return M
