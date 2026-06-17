local M = {}

local current_file = debug.getinfo(1, "S").source:gsub("^@", "")
local current_dir = vim.fs.dirname(current_file)
local assets_dir = current_dir.."/../../assets"

---@class NvimStatusCatConfig
---@field foreground_width integer Width of the foreground image.
---@field width integer Width of the progress bar and background images.
---@field height integer Height of the images.
---@field min_window_width integer If the window width is less than this, don't render there.
---@field bar_length integer The length of the bar rendered in the window.
---@field position number Number between 0 and 1. 0 being the left of the statusline and 1 the right.
---@field background_img_path string Path to the image that will be used as the background.
---@field progress_img_path string Path to the image that will be used as the progress bar.
---@field foreground_img_path string[] Path to the image(s) that will be used as the foreground.
---@field fps integer? Frames per second if you have an animated foreground. Irrelevant otherwise.
local default_config = {
	foreground_width = 4,
	width = 2,
	height = 1,

	min_window_width = 80,

	bar_length = 10,
	position = 0.5,

	background_img_path = assets_dir.."/outerspace.png",
	progress_img_path = assets_dir.."/rainbow.png",
	foreground_img_path = {
		--assets_dir.."/nyan.png",
		assets_dir.."/nyan1.png",
		assets_dir.."/nyan2.png",
		assets_dir.."/nyan3.png",
		assets_dir.."/nyan4.png",
		assets_dir.."/nyan5.png",
		assets_dir.."/nyan6.png",
	},

	fps = 12,
}

---@param opts? NvimStatusCatConfig
function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	local supports, msg = require("nvim-statuscat.utils").supports_img()

	if supports then
		require("nvim-statuscat.render").start_rendering(opts)
	else
		vim.notify("nvim-statuscat: "..msg, vim.log.levels.ERROR)
	end
end

return M
